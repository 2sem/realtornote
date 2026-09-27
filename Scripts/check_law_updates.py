#!/usr/bin/env python3
"""Check the laws behind the study content for amendments since the last review.

For every law in Scripts/laws.json, lists the versions (including 시행예정) whose
시행일자 is newer than the one recorded in Scripts/law_versions.json, pulls the
신구법 비교 of each, and points at the Content parts that likely need editing.

Uses the 국가법령정보 공동활용 Open API (open.law.go.kr). Calls are only accepted
from the IP registered for the key, so this runs locally, not on CI.
The key (OC) comes from $LAW_API_OC or Scripts/.env (`LAW_API_OC=...`, gitignored).

Usage:
    python3 Scripts/check_law_updates.py                  # report changes since last review
    python3 Scripts/check_law_updates.py --since 20250101 # report changes since a date
    python3 Scripts/check_law_updates.py --law 공인중개사법  # only laws whose name contains this
    python3 Scripts/check_law_updates.py --out report.md  # also save the report
    python3 Scripts/check_law_updates.py --update         # mark everything reviewed (after editing content)
"""

import argparse
import datetime
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
ROOT = SCRIPTS.parent
LAWS_FILE = SCRIPTS / "laws.json"
STATE_FILE = SCRIPTS / "law_versions.json"
ENV_FILE = SCRIPTS / ".env"
CONTENT_DIR = ROOT / "Projects/App/Resources/Content"

API = "https://www.law.go.kr/DRF"
PAGE_SIZE = 100
ARTICLE_HEAD = re.compile(r"^\s*(제\d+조(?:의\d+)?)\s*\(([^)]*)\)")
MARKED = re.compile(r"<P>(.*?)</P>", re.S)
PLACEHOLDER = re.compile(r"<\s*신\s*설\s*>")
MAX_HITS_PER_PART = 5


# --- API ---------------------------------------------------------------------

def load_key():
    key = os.environ.get("LAW_API_OC")
    if not key and ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            name, _, value = line.partition("=")
            if name.strip() == "LAW_API_OC":
                key = value.strip().strip('"\'')
    if not key:
        sys.exit(f"LAW_API_OC not set. Put `LAW_API_OC=<your OC>` in {ENV_FILE.relative_to(ROOT)} or export it.")
    return key


def call(key, endpoint, **params):
    query = urllib.parse.urlencode({"OC": key, "type": "JSON", **params})
    with urllib.request.urlopen(f"{API}/{endpoint}?{query}", timeout=30) as response:
        body = response.read().decode("utf-8")
    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        sys.exit(f"{endpoint} {params.get('target')}: non-JSON response (is this target approved for your key?)")
    if "result" in data and "msg" in data:
        # Auth failures come back as a flat {result, msg}; don't echo the request URL (it has the key).
        sys.exit(f"API error: {data['result']} {data['msg']}\n"
                 "Check that the key is approved and your current public IP is registered on open.law.go.kr.")
    time.sleep(0.2)
    return data


def as_list(value):
    if value is None:
        return []
    return [value] if isinstance(value, dict) else value


def newer_versions(key, name, after):
    """Versions of `name` with 시행일자 > after, oldest first, one per 법령일련번호 (MST)."""
    found = {}
    page = 1
    while True:
        data = call(key, "lawSearch.do", target="eflaw", query=name, display=PAGE_SIZE, page=page, sort="efdes")
        rows = as_list(data["LawSearch"].get("law"))
        for row in rows:
            if row["법령명한글"] == name and row["시행일자"] > after:
                mst = row["법령일련번호"]
                # One MST can have several 시행일자 (부칙 phased in); keep the earliest.
                if mst not in found or row["시행일자"] < found[mst]["시행일자"]:
                    found[mst] = row
        # Sorted by 시행일자 desc: once a page reaches `after`, older pages can't match.
        if not rows or len(rows) < PAGE_SIZE or rows[-1]["시행일자"] <= after:
            break
        page += 1
    return sorted(found.values(), key=lambda row: row["시행일자"])


def latest_version(key, name):
    data = call(key, "lawSearch.do", target="eflaw", query=name, display=PAGE_SIZE, sort="efdes")
    rows = [row for row in as_list(data["LawSearch"].get("law")) if row["법령명한글"] == name]
    return rows[0] if rows else None


def comparison(key, mst):
    return call(key, "lawService.do", target="oldAndNew", MST=mst)["OldAndNewService"]


# --- diff → report -----------------------------------------------------------

def plain(text):
    return re.sub(r"\s+", " ", MARKED.sub(r"【\1】", text)).strip()


def changed_articles(articles):
    """{'제37조(감독상의 명령 등)': [changed paragraphs]} for paragraphs with <P> marks."""
    result = {}
    current = "(조문 외)"
    for article in as_list(articles):
        content = article.get("content", "")
        head = ARTICLE_HEAD.match(MARKED.sub(r"\1", content))
        if head:
            current = f"{head.group(1)}({head.group(2)})"
        # `<신 설>` only marks where the new side added text; the new side already shows it.
        if "<P>" in content and not PLACEHOLDER.fullmatch(MARKED.sub(r"\1", content).strip()):
            result.setdefault(current, []).append(content)
    return result


def search_terms(old, new):
    """Old wording that was replaced, plus titles of touched articles — what to grep content for."""
    terms = set()
    for paragraphs in old.values():
        for paragraph in paragraphs:
            for fragment in MARKED.findall(paragraph):
                fragment = fragment.strip(" .,·ㆍ()\"“”")
                if 2 <= len(fragment) <= 20 and re.search(r"[가-힣]{2}", fragment):
                    terms.add(fragment)
    for head in list(old) + list(new):
        title = re.search(r"\(([^)]*)\)", head)
        if title and len(title.group(1)) >= 3:
            terms.add(title.group(1))
    return sorted(terms)


def load_parts():
    if not (CONTENT_DIR / "subjects").exists():
        return None
    parts = {}
    for path in sorted((CONTENT_DIR / "subjects").glob("*.json")):
        subject = json.loads(path.read_text(encoding="utf-8"))
        for chapter in subject["chapters"]:
            for part in chapter["parts"]:
                text_path = CONTENT_DIR / "parts" / f"{part['id']}.txt"
                parts[part["id"]] = {
                    "title": f"{subject['name']} > {chapter['name']} > {part['name']}",
                    "lines": text_path.read_text(encoding="utf-8").splitlines() if text_path.exists() else [],
                }
    return parts


def part_hits(parts, part_ids, terms):
    hits = []
    for part_id in part_ids:
        part = parts.get(part_id)
        if not part:
            continue
        lines = [(number, line.strip()) for number, line in enumerate(part["lines"], 1)
                 if any(term in line for term in terms)]
        if lines:
            hits.append((part_id, part["title"], lines))
    return hits


def report_law(key, law, versions, parts, out):
    name = law["name"]
    today = datetime.date.today().strftime("%Y%m%d")
    out.append(f"## {name}\n")
    for version in versions:
        pending = " **(시행예정)**" if version["시행일자"] > today else ""
        out.append(f"### 시행 {fmt(version['시행일자'])}{pending} — {version['제개정구분명']} "
                   f"(공포 {fmt(version['공포일자'])}, 제{version['공포번호']}호)\n")
        diff = comparison(key, version["법령일련번호"])
        old = changed_articles(diff.get("구조문목록", {}).get("조문"))
        new = changed_articles(diff.get("신조문목록", {}).get("조문"))
        if not old and not new:
            out.append("_신구법 비교 없음 (제정/전부개정/타법개정일 수 있음) — law.go.kr에서 직접 확인._\n")
            continue
        for head in sorted(set(old) | set(new), key=article_order):
            out.append(f"- **{head}**")
            for paragraph in old.get(head, []):
                out.append(f"  - 구: {plain(paragraph)}")
            for paragraph in new.get(head, []):
                out.append(f"  - 신: {plain(paragraph)}")
        out.append("")

        if parts is None:
            continue
        terms = search_terms(old, new)
        hits = part_hits(parts, law["parts"], terms)
        out.append(f"검토할 파트 (검색어: {', '.join(terms) or '없음'}):")
        if not hits:
            out.append(f"- 일치 없음 — 연결 파트 {law['parts']} 직접 확인\n")
            continue
        for part_id, title, lines in hits:
            out.append(f"- parts/{part_id}.txt — {title}")
            for number, line in lines[:MAX_HITS_PER_PART]:
                out.append(f"  - L{number}: {line}")
            if len(lines) > MAX_HITS_PER_PART:
                out.append(f"  - … 외 {len(lines) - MAX_HITS_PER_PART}줄")
        out.append("")


def article_order(head):
    match = re.match(r"제(\d+)조(?:의(\d+))?", head)
    return (int(match.group(1)), int(match.group(2) or 0)) if match else (10**6, 0)


def fmt(date):
    return f"{date[:4]}-{date[4:6]}-{date[6:]}"


# --- main --------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--since", help="report versions with 시행일자 after YYYYMMDD, ignoring recorded state")
    parser.add_argument("--law", help="only laws whose name contains this text")
    parser.add_argument("--out", help="also write the report to this file")
    parser.add_argument("--update", action="store_true", help="record each law's latest version as reviewed")
    args = parser.parse_args()

    key = load_key()
    laws = json.loads(LAWS_FILE.read_text(encoding="utf-8"))["laws"]
    if args.law:
        laws = [law for law in laws if args.law in law["name"]]
    state = json.loads(STATE_FILE.read_text(encoding="utf-8")) if STATE_FILE.exists() else {}

    if args.update:
        for law in laws:
            latest = latest_version(key, law["name"])
            if not latest:
                print(f"! {law['name']}: not found", file=sys.stderr)
                continue
            state[law["name"]] = {
                "법령ID": latest["법령ID"],
                "법령일련번호": latest["법령일련번호"],
                "시행일자": latest["시행일자"],
                "공포일자": latest["공포일자"],
            }
            print(f"✓ {law['name']}: {fmt(latest['시행일자'])}")
        STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Recorded {len(laws)} laws in {STATE_FILE.relative_to(ROOT)}")
        return

    parts = load_parts()
    out = [f"# 법령 개정 확인 ({datetime.date.today().isoformat()})\n"]
    if parts is None:
        out.append(f"_{CONTENT_DIR.relative_to(ROOT)} 없음 (Content.zip 해제 필요) — 파트 검색 생략._\n")

    changed, untracked = [], []
    for law in laws:
        after = args.since or state.get(law["name"], {}).get("시행일자")
        if not after:
            untracked.append(law["name"])
            continue
        print(f"… {law['name']}", file=sys.stderr)
        versions = newer_versions(key, law["name"], after)
        if versions:
            changed.append(law["name"])
            report_law(key, law, versions, parts, out)

    summary = [f"변경 {len(changed)}건 / 확인 {len(laws) - len(untracked)}건"]
    if changed:
        summary.append("변경된 법령: " + ", ".join(changed))
    if untracked:
        summary.append(f"기준 없음 {len(untracked)}건 (--since로 확인하거나 --update로 기준 기록): " + ", ".join(untracked))
    out[1:1] = ["\n".join(f"- {line}" for line in summary) + "\n"]

    report = "\n".join(out)
    print(report)
    if args.out:
        Path(args.out).write_text(report, encoding="utf-8")


if __name__ == "__main__":
    main()
