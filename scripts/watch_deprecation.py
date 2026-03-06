#!/usr/bin/env python3
"""
Deprecation watch script for china-mirror-skills

Fetches key official mirror pages, compares against saved fingerprints,
and creates a GitHub issue if changes are detected.
"""

import hashlib
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import requests
import yaml

# Pages to watch for deprecation/policy changes
WATCH_PAGES = [
    {
        "id": "tuna-pypi",
        "name": "TUNA PyPI Help Page",
        "url": "https://mirrors.tuna.tsinghua.edu.cn/help/pypi/",
    },
    {
        "id": "ustc-pypi",
        "name": "USTC PyPI Help Page",
        "url": "https://mirrors.ustc.edu.cn/help/pypi.html",
    },
    {
        "id": "npmmirror-home",
        "name": "npmmirror Homepage",
        "url": "https://npmmirror.com",
    },
    {
        "id": "tuna-docker-registry",
        "name": "TUNA Docker Registry Help",
        "url": "https://mirrors.tuna.tsinghua.edu.cn/help/docker-registry/",
    },
    {
        "id": "k8s-gcr-announcement",
        "name": "Kubernetes Registry Migration Announcement",
        "url": "https://kubernetes.io/blog/2023/02/06/k8s-gcr-io-freeze-announcement/",
    },
    {
        "id": "tuna-docker-ce",
        "name": "TUNA Docker CE Help Page",
        "url": "https://mirrors.tuna.tsinghua.edu.cn/help/docker-ce/",
    },
    {
        "id": "ustc-cargo",
        "name": "USTC Cargo Mirror Help",
        "url": "https://mirrors.ustc.edu.cn/help/crates.io-index.html",
    },
    {
        "id": "goproxy-cn",
        "name": "goproxy.cn Homepage",
        "url": "https://goproxy.cn",
    },
]

USER_AGENT = "china-mirror-skills/0.1.0 (Deprecation Watch)"
REQUEST_TIMEOUT = 30


def fetch_page_fingerprint(url: str) -> tuple[str | None, str | None]:
    """Fetch a page and return its content hash and a snippet for comparison."""
    try:
        response = requests.get(
            url,
            timeout=REQUEST_TIMEOUT,
            headers={"User-Agent": USER_AGENT},
            allow_redirects=True,
        )
        response.raise_for_status()
        content = response.text
        fingerprint = hashlib.sha256(content.encode("utf-8")).hexdigest()
        # Take a representative snippet (first 2000 chars, stripped of whitespace runs)
        import re
        snippet = re.sub(r'\s+', ' ', content[:2000]).strip()
        return fingerprint, snippet
    except requests.RequestException as e:
        return None, str(e)


def load_fingerprints(path: Path) -> dict:
    """Load saved fingerprints from JSON file."""
    if path.exists():
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_fingerprints(path: Path, fingerprints: dict):
    """Save fingerprints to JSON file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(fingerprints, f, indent=2, ensure_ascii=False)


def create_github_issue(title: str, body: str):
    """Create a GitHub issue via the API."""
    token = os.environ.get("GITHUB_TOKEN")
    repo = os.environ.get("GITHUB_REPOSITORY")

    if not token or not repo:
        print("Warning: GITHUB_TOKEN or GITHUB_REPOSITORY not set, skipping issue creation")
        print(f"Would have created issue: {title}")
        return

    url = f"https://api.github.com/repos/{repo}/issues"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    payload = {
        "title": title,
        "body": body,
        "labels": ["deprecation-watch", "automated"],
    }

    response = requests.post(url, json=payload, headers=headers, timeout=30)
    if response.status_code == 201:
        issue_url = response.json().get("html_url", "")
        print(f"Created issue: {issue_url}")
    else:
        print(f"Failed to create issue: {response.status_code} {response.text}", file=sys.stderr)


def main():
    script_dir = Path(__file__).parent.absolute()
    project_root = script_dir.parent
    fingerprints_path = project_root / "data" / "page_fingerprints.json"

    print("China Mirror Skills - Deprecation Watch")
    print("=" * 40)
    print(f"Watching {len(WATCH_PAGES)} pages...")

    saved = load_fingerprints(fingerprints_path)
    updated = dict(saved)
    changed_pages = []

    for page in WATCH_PAGES:
        page_id = page["id"]
        print(f"Checking: {page['name']} ({page['url']})")

        fingerprint, snippet = fetch_page_fingerprint(page["url"])

        if fingerprint is None:
            print(f"  ERROR: Could not fetch page - {snippet}")
            continue

        old_entry = saved.get(page_id, {})
        old_fingerprint = old_entry.get("fingerprint")

        if old_fingerprint and old_fingerprint != fingerprint:
            print(f"  CHANGED: {page['name']}")
            changed_pages.append({
                "page": page,
                "old_fingerprint": old_fingerprint,
                "new_fingerprint": fingerprint,
                "snippet": snippet,
            })

        updated[page_id] = {
            "name": page["name"],
            "url": page["url"],
            "fingerprint": fingerprint,
            "last_checked": datetime.utcnow().isoformat() + "Z",
            "last_changed": (
                datetime.utcnow().isoformat() + "Z"
                if old_fingerprint != fingerprint
                else old_entry.get("last_changed")
            ),
        }

    # Save updated fingerprints
    save_fingerprints(fingerprints_path, updated)
    print(f"\nUpdated fingerprints saved to: {fingerprints_path}")

    if changed_pages:
        print(f"\n{len(changed_pages)} page(s) changed! Creating GitHub issue...")

        lines = [
            "## Mirror Page Changes Detected",
            "",
            "The following official mirror pages have changed content since the last check.",
            "Please review these pages to determine if any mirrors have been deprecated,",
            "updated, or have new instructions that require updating `data/mirrors.yml`.",
            "",
        ]
        for change in changed_pages:
            page = change["page"]
            lines += [
                f"### [{page['name']}]({page['url']})",
                "",
                f"- **URL**: {page['url']}",
                f"- **Old fingerprint**: `{change['old_fingerprint'][:16]}...`",
                f"- **New fingerprint**: `{change['new_fingerprint'][:16]}...`",
                "",
                "**Action items:**",
                f"- [ ] Visit [{page['url']}]({page['url']}) and check for deprecation notices",
                "- [ ] Update `data/mirrors.yml` if mirror status has changed",
                "- [ ] Update documentation if instructions have changed",
                "",
            ]

        lines += [
            "---",
            f"_Detected at: {datetime.utcnow().isoformat()}Z_",
            "_Generated by deprecation-watch workflow_",
        ]

        title = f"[Deprecation Watch] {len(changed_pages)} mirror page(s) changed"
        body = "\n".join(lines)
        create_github_issue(title, body)
    else:
        print("No page changes detected.")

    print("\nDone.")


if __name__ == "__main__":
    main()
