#!/usr/bin/env python3
"""Refresh upstream M3U commit times and the local playlist time in README."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
BEIJING = timezone(timedelta(hours=8), name="北京时间")
TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
UPSTREAMS = [
    {
        "name": "Guovin/iptv-api",
        "kind": "last_modified",
        "url": "https://guovin.github.io/iptv-api/result.m3u",
    },
    {
        "name": "Guovin/TV",
        "kind": "github_commit",
        "repo": "Guovin/TV",
        "path": "output/result.m3u",
        "ref": "gd",
    },
    {
        "name": "iptv-org 中国",
        "kind": "github_commit",
        "repo": "iptv-org/iptv",
        "path": "streams/cn.m3u",
        "ref": "master",
    },
    {
        "name": "iptv-org 台湾",
        "kind": "github_commit",
        "repo": "iptv-org/iptv",
        "path": "streams/tw.m3u",
        "ref": "master",
    },
    {
        "name": "YanG-1989/m3u",
        "kind": "github_commit",
        "repo": "YanG-1989/m3u",
        "path": "Gather.m3u",
        "ref": "main",
    },
    {
        "name": "fanmingming/live（IPv6）",
        "kind": "github_commit",
        "repo": "fanmingming/live",
        "path": "tv/m3u/ipv6.m3u",
        "ref": "main",
    },
]


def beijing_time(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(BEIJING).strftime(TIME_FORMAT)


def fetch_last_modified(url: str) -> str:
    request = Request(url, method="HEAD", headers={"User-Agent": "iptv-live-readme-updater"})
    with urlopen(request, timeout=20) as response:
        header = response.headers.get("Last-Modified")
    if not header:
        raise ValueError("HTTP 响应没有 Last-Modified")
    parsed = parsedate_to_datetime(header)
    return beijing_time(parsed)


def fetch_github_file_commit(repo: str, path: str, ref: str) -> str:
    query = urlencode({"path": path, "per_page": 1, "sha": ref})
    url = f"https://api.github.com/repos/{repo}/commits?{query}"
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "iptv-live-readme-updater",
    }
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = Request(url, headers=headers)
    with urlopen(request, timeout=20) as response:
        commits = json.load(response)
    if not commits:
        raise ValueError("GitHub API 未返回该文件的提交记录")
    timestamp = commits[0]["commit"]["committer"]["date"]
    return beijing_time(datetime.fromisoformat(timestamp.replace("Z", "+00:00")))


def fetch_upstream_time(source: dict[str, str]) -> str:
    if source["kind"] == "last_modified":
        return fetch_last_modified(source["url"])
    return fetch_github_file_commit(source["repo"], source["path"], source["ref"])


def last_upstream_time(readme: str, name: str) -> str:
    for line in readme.splitlines():
        fields = [field.strip() for field in line.split("|")]
        if len(fields) >= 6 and fields[1] == name:
            return fields[4]
    raise ValueError(f"README 中找不到上游行：{name}")


def replace_upstream_time(readme: str, name: str, value: str) -> str:
    lines = readme.splitlines(keepends=True)
    for index, line in enumerate(lines):
        fields = line.rstrip("\r\n").split("|")
        if len(fields) >= 6 and fields[1].strip() == name:
            fields[4] = f" {value} "
            lines[index] = "|".join(fields) + ("\n" if line.endswith("\n") else "")
            return "".join(lines)
    raise ValueError(f"无法更新 README 中的上游时间：{name}")


def playlist_files_changed() -> bool:
    result = subprocess.run(
        ["git", "diff", "--quiet", "HEAD", "--", "IPTV_ALL.m3u", "IPTV_ADULT.m3u"],
        cwd=ROOT,
        check=False,
    )
    if result.returncode not in (0, 1):
        raise RuntimeError("无法检查 M3U 文件是否相对 HEAD 发生变化")
    return result.returncode == 1


def refresh_readme(now: datetime | None = None) -> str:
    readme = README.read_text(encoding="utf-8")
    for source in UPSTREAMS:
        try:
            timestamp = fetch_upstream_time(source)
            print(f"{source['name']}: {timestamp}（北京时间）")
        except (HTTPError, URLError, TimeoutError, OSError, ValueError, KeyError) as error:
            timestamp = last_upstream_time(readme, source["name"])
            print(
                f"{source['name']}: 查询失败，保留上次已核实时间 {timestamp}（北京时间）：{error}",
                file=sys.stderr,
            )
        readme = replace_upstream_time(readme, source["name"], timestamp)

    if playlist_files_changed():
        updated_at = beijing_time(now or datetime.now(BEIJING))
        marker = re.compile(
            r"(本仓库 M3U 文件最近更新时间（北京时间）：\*\*)[^*]+(\*\*。)"
        )
        readme, count = marker.subn(rf"\g<1>{updated_at}\g<2>", readme, count=1)
        if count != 1:
            raise ValueError("README 中缺少本仓库 M3U 更新时间标记")
        print(f"本仓库 M3U 文件有变化，更新时间设为 {updated_at}（北京时间）")

    README.write_text(readme, encoding="utf-8", newline="\n")
    return readme


if __name__ == "__main__":
    refresh_readme()
