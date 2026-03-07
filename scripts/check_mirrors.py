#!/usr/bin/env python3
"""
Mirror health check script for china-mirror-skills

Validates HTTP(S) connectivity to all mirrors defined in data/mirrors.yml
and generates a health report.
"""

import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional

import requests
import yaml

# Fallback constants (overridden by health_check section in mirrors.yml)
DEFAULT_TIMEOUT = 30
MAX_WORKERS = 10
DEFAULT_USER_AGENT = "china-mirror-skills/0.1.0 (Health Check)"


@dataclass
class MirrorCheckResult:
    """Result of a single mirror health check"""
    id: str
    name: str
    category: str
    url: str
    # Possible status values:
    #   ok | timeout | dns_error | tls_error | connection_error
    #   http_<code>  (e.g. http_403, http_404)
    #   http_5xx     (any 5xx, retried)
    #   unexpected_response | error | unknown
    status: str
    http_status: Optional[int] = None
    response_time_ms: Optional[float] = None
    error_message: Optional[str] = None
    checked_url: Optional[str] = None   # actual probe URL (may differ from mirror URL)
    verify_type: Optional[str] = None   # http | go_proxy | …
    is_inconclusive: bool = False
    timestamp: str = ""


def load_mirrors(yaml_path: Path) -> dict:
    """Load mirror configuration from YAML file"""
    with open(yaml_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def _acceptable_statuses(verify_config: dict) -> list[int]:
    """Return the list of HTTP status codes that count as 'ok'.

    Supports both:
      expect_status: 200           (single int)
      expect_status_in: [200, 401] (list)
    """
    if 'expect_status_in' in verify_config:
        return list(verify_config['expect_status_in'])
    return [verify_config.get('expect_status', 200)]


def _classify_connection_error(exc: Exception) -> tuple[str, str]:
    """Return (status_string, human_message) for a requests.ConnectionError."""
    msg = str(exc).lower()
    if ('name or service not known' in msg or 'nodename nor servname' in msg
            or 'getaddrinfo failed' in msg or 'failed to resolve' in msg):
        return 'dns_error', f"DNS resolution failed: {exc}"
    if 'ssl' in msg or 'certificate' in msg or 'handshake' in msg:
        return 'tls_error', f"TLS/SSL error: {exc}"
    return 'connection_error', str(exc)


def check_mirror(mirror: dict, timeout: int = DEFAULT_TIMEOUT,
                 retries: int = 0, user_agent: str = DEFAULT_USER_AGENT) -> MirrorCheckResult:
    """Check health of a single mirror, with optional retry on transient failures.

    Retry policy (retries = N means up to N+1 attempts total):
    - Retried: timeout, connection_error, dns_error, tls_error, http_5xx
    - NOT retried: http_4xx and other deterministic HTTP errors
    """
    verify_config = mirror.get('verify', {})
    check_url = verify_config.get('url', mirror['url'])
    acceptable = _acceptable_statuses(verify_config)
    verify_type = verify_config.get('type', 'http')
    method = verify_config.get('method', 'get').lower()
    inconclusive_statuses = {
        f"http_{code}" for code in verify_config.get('inconclusive_statuses', [])
    }

    # github_proxy: probe URL is prefix + test_url
    if verify_type == 'github_proxy':
        prefix = verify_config.get('prefix', mirror['url'])
        test_url = verify_config.get('test_url', '')
        check_url = prefix + test_url

    result = MirrorCheckResult(
        id=mirror['id'],
        name=mirror['name'],
        category=mirror['category'],
        url=mirror['url'],
        status='unknown',
        checked_url=check_url,
        verify_type=verify_type,
        timestamp=datetime.utcnow().isoformat() + 'Z',
    )

    for attempt in range(retries + 1):
        should_retry = False

        try:
            start_time = time.time()
            request_kwargs = {
                'timeout': timeout,
                'headers': {'User-Agent': user_agent},
                'allow_redirects': True,
            }
            if method == 'head':
                response = requests.head(check_url, **request_kwargs)
            else:
                response = requests.get(check_url, **request_kwargs)
            elapsed_ms = (time.time() - start_time) * 1000

            result.response_time_ms = round(elapsed_ms, 2)
            result.http_status = response.status_code

            if response.status_code in acceptable:
                # go_proxy: on 200 also validate JSON structure
                if verify_type == 'go_proxy' and response.status_code == 200:
                    try:
                        data = response.json()
                        if isinstance(data, dict) and 'Version' in data and 'Time' in data:
                            result.status = 'ok'
                        else:
                            result.status = 'unexpected_response'
                            result.error_message = (
                                "go_proxy @v/*.info JSON is missing Version/Time fields"
                            )
                    except ValueError:
                        result.status = 'unexpected_response'
                        result.error_message = "go_proxy @v/*.info returned non-JSON body"
                else:
                    result.status = 'ok'

            elif 500 <= response.status_code < 600:
                result.status = 'http_5xx'
                result.error_message = f"Server error: {response.status_code}"
                should_retry = True  # 5xx is transient, worth retrying

            else:
                # Deterministic HTTP error — no retry
                result.status = f'http_{response.status_code}'
                result.is_inconclusive = result.status in inconclusive_statuses
                exp = (acceptable[0] if len(acceptable) == 1 else acceptable)
                result.error_message = f"Expected {exp}, got {response.status_code}"

        except requests.exceptions.Timeout:
            result.status = 'timeout'
            result.error_message = f"Request timed out after {timeout}s"
            should_retry = True

        except requests.exceptions.ConnectionError as e:
            result.status, result.error_message = _classify_connection_error(e)
            should_retry = True  # all connection-level errors are transient

        except requests.exceptions.RequestException as e:
            result.status = 'error'
            result.error_message = str(e)
            # Don't retry unknown request errors

        if not should_retry or attempt >= retries:
            break

        # Exponential-ish backoff before next attempt
        time.sleep(0.8 * (attempt + 1))

    return result


def _print_result(result: MirrorCheckResult):
    """Print a single mirror check result line."""
    icon = "✓" if result.status == 'ok' else "✗"
    base = f"{icon} {result.name} ({result.category}): {result.status}"
    if result.status != 'ok' and result.error_message:
        short_msg = result.error_message[:80]
        print(f"{base}  — {short_msg}")
    else:
        print(base)


def check_all_mirrors(mirrors_data: dict, max_workers: int = MAX_WORKERS) -> list[MirrorCheckResult]:
    """Check health of all mirrors concurrently"""
    mirrors = mirrors_data.get('mirrors', [])

    health_config = mirrors_data.get('health_check', {})
    timeout = health_config.get('timeout', DEFAULT_TIMEOUT)
    retries = health_config.get('retries', 0)
    user_agent = health_config.get('user_agent', DEFAULT_USER_AGENT)
    parallel = health_config.get('parallel', True)

    results = []

    if parallel and max_workers > 1:
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_mirror = {
                executor.submit(check_mirror, m, timeout, retries, user_agent): m
                for m in mirrors
            }
            for future in as_completed(future_to_mirror):
                result = future.result()
                results.append(result)
                _print_result(result)
    else:
        for m in mirrors:
            result = check_mirror(m, timeout, retries, user_agent)
            results.append(result)
            _print_result(result)

    return results


def generate_report(results: list[MirrorCheckResult], mirrors_data: dict) -> dict:
    """Generate a comprehensive health report"""
    total = len(results)
    ok_count = sum(1 for r in results if r.status == 'ok')
    non_ok_count = total - ok_count

    # Per-category statistics
    category_stats = {}
    for result in results:
        cat = result.category
        if cat not in category_stats:
            category_stats[cat] = {'total': 0, 'ok': 0, 'non_ok': 0}
        category_stats[cat]['total'] += 1
        if result.status == 'ok':
            category_stats[cat]['ok'] += 1
        else:
            category_stats[cat]['non_ok'] += 1

    # Status breakdown across all mirrors
    status_breakdown: dict[str, int] = {}
    for result in results:
        status_breakdown[result.status] = status_breakdown.get(result.status, 0) + 1

    report = {
        'metadata': {
            'generated_at': datetime.utcnow().isoformat() + 'Z',
            'version': mirrors_data.get('version', 'unknown'),
            'mirror_data_updated': mirrors_data.get('updated_at', 'unknown'),
        },
        'summary': {
            'total_mirrors': total,
            'healthy': ok_count,
            'unhealthy': non_ok_count,
            'health_rate': round(ok_count / total * 100, 2) if total > 0 else 0,
            'category_stats': category_stats,
            'status_breakdown': status_breakdown,
        },
        'results': [asdict(r) for r in results],
        'recommendations': generate_recommendations(results, mirrors_data),
    }

    return report


def generate_recommendations(results: list[MirrorCheckResult], mirrors_data: dict) -> list[dict]:
    """Generate per-category recommendations based on check results"""
    category_results: dict[str, list[MirrorCheckResult]] = {}
    for result in results:
        category_results.setdefault(result.category, []).append(result)

    recommendations = []
    for category, cat_results in category_results.items():
        working = [r for r in cat_results if r.status == 'ok']
        failed = [r for r in cat_results if r.status != 'ok']
        definitive_failures = [r for r in failed if not r.is_inconclusive]
        inconclusive_failures = [r for r in failed if r.is_inconclusive]

        if not working and definitive_failures:
            recommendations.append({
                'category': category,
                'severity': 'critical',
                'message': f'No working mirrors found for {category}. All mirrors failed.',
                'action': 'Please check your network connection or report this issue.',
            })
        elif not working and inconclusive_failures:
            recommendations.append({
                'category': category,
                'severity': 'warning',
                'message': (
                    f'No mirror probe returned a definitive success for {category}; '
                    'current failures are inconclusive.'
                ),
                'action': 'Check the official help page or validate manually from a real client.',
            })
        elif failed:
            best = min(working, key=lambda r: r.response_time_ms or float('inf'))
            recommendations.append({
                'category': category,
                'severity': 'warning',
                'message': f'{len(failed)} mirror(s) failed for {category}.',
                'action': f'Recommended mirror: {best.name} ({best.url})',
            })

    return recommendations


def count_critical_category_failures(results: list[MirrorCheckResult]) -> int:
    """Return the number of categories where every single mirror failed.

    A category is 'critical' only when it has zero working mirrors.
    Individual mirror failures within a category that still has at least
    one ok mirror are not counted as critical.
    """
    by_cat: dict[str, list[MirrorCheckResult]] = {}
    for r in results:
        by_cat.setdefault(r.category, []).append(r)

    critical = 0
    for items in by_cat.values():
        if not any(r.status == 'ok' for r in items) and any(not r.is_inconclusive for r in items):
            critical += 1
    return critical


def save_report(report: dict, output_path: Path):
    """Save report to JSON file"""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"\nReport saved to: {output_path}")


def print_summary(report: dict):
    """Print a human-readable summary"""
    summary = report['summary']

    print("\n" + "=" * 60)
    print("MIRROR HEALTH CHECK SUMMARY")
    print("=" * 60)
    print(f"Generated: {report['metadata']['generated_at']}")
    print(f"Total mirrors checked: {summary['total_mirrors']}")
    print(f"Healthy: {summary['healthy']} ({summary['health_rate']}%)")
    print(f"Unhealthy: {summary['unhealthy']}")

    print("\nCategory Statistics:")
    for cat, stats in summary['category_stats'].items():
        icon = "✓" if stats['non_ok'] == 0 else "⚠"
        print(f"  {icon} {cat}: {stats['ok']}/{stats['total']} working")

    if report['recommendations']:
        print("\nRecommendations:")
        for rec in report['recommendations']:
            icon = "🔴" if rec['severity'] == 'critical' else "🟡"
            print(f"  {icon} [{rec['category']}] {rec['message']}")
            print(f"      Action: {rec['action']}")

    print("=" * 60)


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description='Check health of China mirror sources')
    parser.add_argument('--output', '-o', type=str, default=None,
                        help='Path to write JSON report (default: reports/report.json)')
    args = parser.parse_args()

    script_dir = Path(__file__).parent.absolute()
    project_root = script_dir.parent
    mirrors_path = project_root / 'data' / 'mirrors.yml'
    report_path = (
        Path(args.output) if args.output else project_root / 'reports' / 'report.json'
    )

    print("China Mirror Skills - Health Check")
    print("=" * 40)
    print(f"Mirrors file: {mirrors_path}")

    if not mirrors_path.exists():
        print(f"Error: Mirrors file not found: {mirrors_path}", file=sys.stderr)
        sys.exit(1)

    print("Loading mirrors configuration...")
    mirrors_data = load_mirrors(mirrors_path)
    mirrors = mirrors_data.get('mirrors', [])
    health_config = mirrors_data.get('health_check', {})
    retries = health_config.get('retries', 0)
    print(f"Loaded {len(mirrors)} mirrors (retries={retries})")

    print("\nChecking mirror health...")
    print("-" * 40)

    max_workers = health_config.get('max_workers', MAX_WORKERS)
    results = check_all_mirrors(mirrors_data, max_workers)

    report = generate_report(results, mirrors_data)
    save_report(report, report_path)
    print_summary(report)

    # Exit 1 only when at least one entire category has zero working mirrors
    critical_failures = count_critical_category_failures(results)
    if critical_failures > 0:
        print(f"\n⚠️  {critical_failures} category/categories have NO working mirrors")
        sys.exit(1)
    else:
        print("\n✅ Every category has at least one working mirror")
        sys.exit(0)


if __name__ == '__main__':
    main()
