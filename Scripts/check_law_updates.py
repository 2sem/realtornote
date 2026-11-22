#!/usr/bin/env python3
"""Check the laws behind the study content for amendments since the last review.

For every law in Scripts/laws.json, lists the versions (including 시행예정) whose
시행일자 is newer than the one recorded in Scripts/law_versions.json, pulls the
신구법 비교 of each, and points at the Content parts that likely need editing.

Uses the 국가법령정보 공동활용 Open API (open.law.go.kr). Calls are only accepted
from the IP registered for the key, so this runs locally, not on CI.
The key (OC) comes from $LAW_API_OC or Scripts/.env (`LAW_API_OC=...`, gitignored).

--download writes (gitignored) Laws/:
    Laws/REPORT.md                       the report below
    Laws/pending.json                    changed laws → versions, files, Content parts to review
    Laws/<법령명>/<시행일자>_<MST>.md      신구법 비교 + review hits, 제개정이유, full text of that version

Usage:
    python3 Scripts/check_law_updates.py                  # report changes since last review
    python3 Scripts/check_law_updates.py --since 20250101 # report changes since a date
    python3 Scripts/check_law_updates.py --law 공인중개사법  # only laws whose name contains this
    python3 Scripts/check_law_updates.py --out report.md  # also save the report
    python3 Scripts/check_law_updates.py --download       # also save each changed version to Laws/
    python3 Scripts/check_law_updates.py --update         # mark reviewed up to the exam date (after editing content)

The exam date comes from Scripts/exam.json (see exam_calendar.py): versions taking effect on or
before it are "대상" (must be reflected); later ones are "이월" (next exam cycle). --update records,
per law, the latest version in force on the exam date, so carried-over versions are still reported
next cycle.
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
sys.path.insert(0, str(SCRIPTS))
import exam_calendar  # noqa: E402

ROOT = SCRIPTS.parent
LAWS_FILE = SCRIPTS / "laws.json"
STATE_FILE = SCRIPTS / "law_versions.json"
ENV_FILE = SCRIPTS / ".env"
CONTENT_DIR = ROOT / "Projects/App/Resources/Content"
LAWS_DIR = ROOT / "Laws"

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


def latest_version_on(key, name, date):
    """Latest version of `name` whose 시행일자 is on or before `date` (YYYYMMDD)."""
    data = call(key, "lawSearch.do", target="eflaw", query=name, display=PAGE_SIZE, sort="efdes")
    rows = [row for row in as_list(data["LawSearch"].get("law"))
            if row["법령명한글"] == name and row["시행일자"] <= date]
    return rows[0] if rows else None


def comparison(key, mst):
    return call(key, "lawService.do", target="oldAndNew", MST=mst)["OldAndNewService"]


def full_text(key, version):
    return call(key, "lawService.do", target="eflaw", MST=version["법령일련번호"], efYd=version["시행일자"])["법령"]


# --- full text → markdown ----------------------------------------------------

def lines_of(value):
    """Flatten the API's str | [str] | [[str]] text fields into lines."""
    if isinstance(value, str):
        return [value.rstrip()] if value.strip() else []
    if isinstance(value, list):
        return [line for item in value for line in lines_of(item)]
    return []


def render_articles(articles):
    out = []
    for article in as_list(articles):
        if article.get("조문여부") == "전문":  # 장/절 headings
            out.append(f"\n#### {article.get('조문내용', '').strip()}\n")
            continue
        out.extend(lines_of(article.get("조문내용")))
        for paragraph in as_list(article.get("항")):
            out.extend("  " + line.strip() for line in lines_of(paragraph.get("항내용")))
            for item in as_list(paragraph.get("호")):
                out.extend("    " + line.strip() for line in lines_of(item.get("호내용")))
                for sub in as_list(item.get("목")):
                    out.extend("      " + line.strip() for line in lines_of(sub.get("목내용")))
        out.append("")
    return out


def write_version(key, law, version, section, out_dir):
    law_text = full_text(key, version)
    reason = lines_of((law_text.get("제개정이유") or {}).get("제개정이유내용"))
    path = out_dir / law["name"] / f"{version['시행일자']}_{version['법령일련번호']}.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    body = [f"# {law['name']}", "", *section, "", "## 제개정이유", "", *(reason or ["(없음)"]),
            "", "## 전문 (이 버전 기준)", "", *render_articles((law_text.get("조문") or {}).get("조문단위"))]
    path.write_text("\n".join(body) + "\n", encoding="utf-8")
    return path


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


def report_law(key, law, versions, parts, out, download_dir=None, exam_date=None):
    """Appends the law's report to `out`; with download_dir, also saves each version and returns their entries."""
    name = law["name"]
    downloaded = []
    today = datetime.date.today().strftime("%Y%m%d")
    out.append(f"## {name}\n")
    for version in versions:
        start = len(out)
        version_report(key, law, version, today, parts, out, exam_date)
        if download_dir:
            path = write_version(key, law, version, out[start:], download_dir)
            downloaded.append({
                "시행일자": version["시행일자"],
                "공포일자": version["공포일자"],
                "법령일련번호": version["법령일련번호"],
                "시행예정": version["시행일자"] > today,
                "in_scope": exam_calendar.in_scope(version["시행일자"], exam_date),
                "file": str(path.relative_to(ROOT)),
            })
    return downloaded


def version_report(key, law, version, today, parts, out, exam_date=None):
    pending = " **(시행예정)**" if version["시행일자"] > today else ""
    if not exam_calendar.in_scope(version["시행일자"], exam_date):
        pending += " **(이월: 시험일 이후 시행)**"
    out.append(f"### 시행 {fmt(version['시행일자'])}{pending} — {version['제개정구분명']} "
               f"(공포 {fmt(version['공포일자'])}, 제{version['공포번호']}호)\n")
    diff = comparison(key, version["법령일련번호"])
    old = changed_articles(diff.get("구조문목록", {}).get("조문"))
    new = changed_articles(diff.get("신조문목록", {}).get("조문"))
    if not old and not new:
        out.append("_신구법 비교 없음 (제정/전부개정/타법개정일 수 있음) — law.go.kr에서 직접 확인._\n")
        return
    for head in sorted(set(old) | set(new), key=article_order):
        out.append(f"- **{head}**")
        for paragraph in old.get(head, []):
            out.append(f"  - 구: {plain(paragraph)}")
        for paragraph in new.get(head, []):
            out.append(f"  - 신: {plain(paragraph)}")
    out.append("")

    if parts is None:
        return
    terms = search_terms(old, new)
    hits = part_hits(parts, law["parts"], terms)
    out.append(f"검토할 파트 (검색어: {', '.join(terms) or '없음'}):")
    if not hits:
        out.append(f"- 일치 없음 — 연결 파트 {law['parts']} 직접 확인\n")
        return
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
    parser.add_argument("--download", action="store_true",
                        help=f"save each changed version (diff, 제개정이유, full text) to {LAWS_DIR.relative_to(ROOT)}/")
    parser.add_argument("--update", action="store_true", help="record each law's latest version as reviewed")
    args = parser.parse_args()

    key = load_key()
    laws = json.loads(LAWS_FILE.read_text(encoding="utf-8"))["laws"]
    if args.law:
        laws = [law for law in laws if args.law in law["name"]]
    state = json.loads(STATE_FILE.read_text(encoding="utf-8")) if STATE_FILE.exists() else {}
    exam = exam_calendar.status()

    if args.update:
        for law in laws:
            # Baseline = latest version in force on the exam date, so versions taking effect after
            # it stay "pending" for the next cycle. Without a configured exam, the latest overall.
            latest = (latest_version_on(key, law["name"], exam["exam_date"]) if exam["exam_date"]
                      else latest_version(key, law["name"]))
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
        print(f"Recorded {len(laws)} laws in {STATE_FILE.relative_to(ROOT)} "
              f"(versions in force on {fmt(exam['exam_date']) if exam['exam_date'] else 'today'})")
        return

    parts = load_parts()
    out = [f"# 법령 개정 확인 ({datetime.date.today().isoformat()})\n"]
    if exam["exam_date"]:
        out.append(f"> 시험일 {fmt(exam['exam_date'])} ({exam['phase']}) — {exam['advice']}\n")
    if parts is None:
        out.append(f"_{CONTENT_DIR.relative_to(ROOT)} 없음 (Content.zip 해제 필요) — 파트 검색 생략._\n")

    download_dir = LAWS_DIR if args.download else None
    changed, untracked, pending = [], [], []
    n_scope = n_later = 0
    for law in laws:
        after = args.since or state.get(law["name"], {}).get("시행일자")
        if not after:
            untracked.append(law["name"])
            continue
        print(f"… {law['name']}", file=sys.stderr)
        versions = newer_versions(key, law["name"], after)
        if versions:
            changed.append(law["name"])
            downloaded = report_law(key, law, versions, parts, out, download_dir, exam["exam_date"])
            in_scope = [v for v in versions if exam_calendar.in_scope(v["시행일자"], exam["exam_date"])]
            n_scope += len(in_scope)
            n_later += len(versions) - len(in_scope)
            if downloaded:
                pending.append({"name": law["name"], "parts": law["parts"], "versions": downloaded})

    summary = [f"변경 {len(changed)}건 / 확인 {len(laws) - len(untracked)}건"]
    if exam["exam_date"]:
        summary.append(f"시험일({fmt(exam['exam_date'])}) 기준: 반영 대상 {n_scope}건 / 이월(시험일 이후 시행) {n_later}건 — {exam['advice']}")
    if changed:
        summary.append("변경된 법령: " + ", ".join(changed))
    if untracked:
        summary.append(f"기준 없음 {len(untracked)}건 (--since로 확인하거나 --update로 기준 기록): " + ", ".join(untracked))
    out[1:1] = ["\n".join(f"- {line}" for line in summary) + "\n"]

    report = "\n".join(out)
    print(report)
    if args.out:
        Path(args.out).write_text(report, encoding="utf-8")
    if download_dir:
        download_dir.mkdir(exist_ok=True)
        (download_dir / "REPORT.md").write_text(report, encoding="utf-8")
        (download_dir / "pending.json").write_text(json.dumps({
            "checked": datetime.date.today().isoformat(),
            "since": args.since,
            "exam": {"date": exam["exam_date"], "phase": exam["phase"], "days_left": exam["days_left"]},
            "laws": pending,
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Saved {sum(len(law['versions']) for law in pending)} versions to {download_dir.relative_to(ROOT)}/",
              file=sys.stderr)


if __name__ == "__main__":
    main()
