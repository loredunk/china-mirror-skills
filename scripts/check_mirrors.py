#!/usr/bin/env python3
"""
Mirror health check script for china-mirror-skills

Validates HTTP(S) connectivity to all mirrors defined in data/mirrors.yml
and generates a health report.
"""

import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional

import requests
import yaml

# Configuration
DEFAULT_TIMEOUT = 30
MAX_WORKERS = 10
USER_AGENT = "china-mirror-skills/0.1.0 (Health Check)"


@dataclass
class MirrorCheckResult:
    """Result of a single mirror health check"""
    id: str
    name: str
    category: str
    url: str
    status: str  # ok, failed, timeout, error
    http_status: Optional[int] = None
    response_time_ms: Optional[float] = None
    error_message: Optional[str] = None
    timestamp: str = ""


def load_mirrors(yaml_path: Path) -> dict:
    """Load mirror configuration from YAML file"""
    with open(yaml_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def check_mirror(mirror: dict, timeout: int = DEFAULT_TIMEOUT) -> MirrorCheckResult:
    """Check health of a single mirror"""
    mirror_id = mirror['id']
    name = mirror['name']
    category = mirror['category']
    verify_config = mirror.get('verify', {})

    result = MirrorCheckResult(
        id=mirror_id,
        name=name,
        category=category,
        url=mirror['url'],
        status='unknown',
        timestamp=datetime.utcnow().isoformat() + 'Z'
    )

    # Get verification URL
    check_url = verify_config.get('url', mirror['url'])
    expected_status = verify_config.get('expect_status', 200)

    try:
        start_time = time.time()
        response = requests.get(
            check_url,
            timeout=timeout,
            headers={'User-Agent': USER_AGENT},
            allow_redirects=True
        )
        response_time = (time.time() - start_time) * 1000  # Convert to ms

        result.response_time_ms = round(response_time, 2)
        result.http_status = response.status_code

        # Check if status matches expectation
        if response.status_code == expected_status:
            result.status = 'ok'
        elif mirror.get('status') == 'deprecated' and response.status_code == 403:
            # Special case: deprecated mirrors may return 403
            result.status = 'ok' if expected_status == 403 else 'failed'
        else:
            result.status = 'unexpected_status'
            result.error_message = f"Expected {expected_status}, got {response.status_code}"

    except requests.exceptions.Timeout:
        result.status = 'timeout'
        result.error_message = f"Request timed out after {timeout}s"
    except requests.exceptions.ConnectionError as e:
        result.status = 'connection_error'
        result.error_message = str(e)
    except requests.exceptions.RequestException as e:
        result.status = 'error'
        result.error_message = str(e)

    return result


def check_all_mirrors(mirrors_data: dict, max_workers: int = MAX_WORKERS) -> list[MirrorCheckResult]:
    """Check health of all mirrors concurrently"""
    mirrors = mirrors_data.get('mirrors', [])
    results = []

    # Get health check config
    health_config = mirrors_data.get('health_check', {})
    timeout = health_config.get('timeout', DEFAULT_TIMEOUT)
    parallel = health_config.get('parallel', True)

    if parallel and max_workers > 1:
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_mirror = {
                executor.submit(check_mirror, mirror, timeout): mirror
                for mirror in mirrors
            }

            for future in as_completed(future_to_mirror):
                result = future.result()
                results.append(result)
                # Print progress
                status_icon = "✓" if result.status == 'ok' else "✗"
                print(f"{status_icon} {result.name} ({result.category}): {result.status}")
    else:
        # Sequential check
        for mirror in mirrors:
            result = check_mirror(mirror, timeout)
            results.append(result)
            status_icon = "✓" if result.status == 'ok' else "✗"
            print(f"{status_icon} {result.name} ({result.category}): {result.status}")

    return results


def generate_report(results: list[MirrorCheckResult], mirrors_data: dict) -> dict:
    """Generate a comprehensive health report"""
    total = len(results)
    ok_count = sum(1 for r in results if r.status == 'ok')
    failed_count = total - ok_count

    # Group by category
    category_stats = {}
    for result in results:
        cat = result.category
        if cat not in category_stats:
            category_stats[cat] = {'total': 0, 'ok': 0, 'failed': 0}
        category_stats[cat]['total'] += 1
        if result.status == 'ok':
            category_stats[cat]['ok'] += 1
        else:
            category_stats[cat]['failed'] += 1

    # Group by status
    status_breakdown = {}
    for result in results:
        status = result.status
        status_breakdown[status] = status_breakdown.get(status, 0) + 1

    report = {
        'metadata': {
            'generated_at': datetime.utcnow().isoformat() + 'Z',
            'version': mirrors_data.get('version', 'unknown'),
            'mirror_data_updated': mirrors_data.get('updated_at', 'unknown'),
        },
        'summary': {
            'total_mirrors': total,
            'healthy': ok_count,
            'unhealthy': failed_count,
            'health_rate': round(ok_count / total * 100, 2) if total > 0 else 0,
            'category_stats': category_stats,
            'status_breakdown': status_breakdown,
        },
        'results': [asdict(r) for r in results],
        'recommendations': generate_recommendations(results, mirrors_data)
    }

    return report


def generate_recommendations(results: list[MirrorCheckResult], mirrors_data: dict) -> list[dict]:
    """Generate recommendations based on check results"""
    recommendations = []

    # Group by category and find best working mirror
    category_results = {}
    for result in results:
        cat = result.category
        if cat not in category_results:
            category_results[cat] = []
        category_results[cat].append(result)

    for category, cat_results in category_results.items():
        working = [r for r in cat_results if r.status == 'ok']
        failed = [r for r in cat_results if r.status != 'ok']

        if not working and failed:
            recommendations.append({
                'category': category,
                'severity': 'critical',
                'message': f'No working mirrors found for {category}. All mirrors failed.',
                'action': 'Please check your network connection or report this issue.'
            })
        elif failed:
            # Find the best working mirror (lowest response time)
            best = min(working, key=lambda r: r.response_time_ms or float('inf'))
            recommendations.append({
                'category': category,
                'severity': 'warning',
                'message': f'{len(failed)} mirror(s) failed for {category}.',
                'action': f'Recommended mirror: {best.name} ({best.url})'
            })

    return recommendations


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
        status = "✓" if stats['failed'] == 0 else "⚠"
        print(f"  {status} {cat}: {stats['ok']}/{stats['total']} working")

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

    # Determine paths
    script_dir = Path(__file__).parent.absolute()
    project_root = script_dir.parent
    mirrors_path = project_root / 'data' / 'mirrors.yml'
    report_path = Path(args.output) if args.output else project_root / 'reports' / 'report.json'

    print("China Mirror Skills - Health Check")
    print("=" * 40)
    print(f"Mirrors file: {mirrors_path}")

    if not mirrors_path.exists():
        print(f"Error: Mirrors file not found: {mirrors_path}", file=sys.stderr)
        sys.exit(1)

    # Load mirrors configuration
    print("Loading mirrors configuration...")
    mirrors_data = load_mirrors(mirrors_path)
    mirrors = mirrors_data.get('mirrors', [])
    print(f"Loaded {len(mirrors)} mirrors")

    # Check all mirrors
    print("\nChecking mirror health...")
    print("-" * 40)

    health_config = mirrors_data.get('health_check', {})
    max_workers = health_config.get('max_workers', MAX_WORKERS)

    results = check_all_mirrors(mirrors_data, max_workers)

    # Generate and save report
    report = generate_report(results, mirrors_data)
    save_report(report, report_path)

    # Print summary
    print_summary(report)

    # Exit with error code if any critical failures
    critical_failures = sum(1 for r in results
                           if r.status != 'ok' and r.status != 'deprecated')
    if critical_failures > 0:
        print(f"\n⚠️  {critical_failures} mirrors are unhealthy")
        sys.exit(1)
    else:
        print("\n✅ All mirrors are healthy")
        sys.exit(0)


if __name__ == '__main__':
    main()
