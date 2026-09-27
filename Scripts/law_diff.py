#!/usr/bin/env python3
"""Compact, per-part law diffs for updating the study content with few tokens.

Instead of reading every amendment in between, compares the version in force on
--from (when the content was last updated) with the version in force on --to
(the exam date), limited to the articles a part covers (Scripts/part_articles.json),
with 개정 tags and common wording-only changes normalized away.

Usage:
    python3 Scripts/law_diff.py toc 공인중개사법              # 장 / 조 titles, to pick a part's articles
    python3 Scripts/law_diff.py diff --part 38               # net diff for every law mapped to part 38
    python3 Scripts/law_diff.py diff --part 38 --from 20241212 --to 20261031
    python3 Scripts/law_diff.py article 공인중개사법 41 41의2   # exact text of articles (exam-date version)

part_articles.json: {"38": {"공인중개사법": "41-44", "공인중개사법 시행령": "30-35"}}
Spec: comma-separated article numbers or ranges; a range includes 가지 articles (41-44 covers 41의2).
"" = the law doesn't touch this part. A law mapped to the part in laws.json but missing
here is diffed in full, with a hint to add it.

Full texts are cached in Laws/cache/ (gitignored).
"""

import argparse
import difflib
import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_law_updates as clu  # noqa: E402  (API key, call(), text rendering)

PART_ARTICLES_FILE = clu.SCRIPTS / "part_articles.json"
CACHE_DIR = clu.LAWS_DIR / "cache"
DEFAULT_FROM = "20241212"  # last content update (realtornote.xlsx)
DEFAULT_TO = "20261031"    # 2026 제37회 시험일

# Annotations the API appends to amended text — they change on every amendment.
ANNOTATIONS = re.compile(r"\s*[<\[]\s*(?:개정|신설|본조신설|전문개정|제목개정|종전|삭제|시행일|타법개정|본조제목개정)[^>\]]*[>\]]")
# Wording-only 법령 정비 (알기 쉬운 법령 만들기) — not a change in meaning.
WORDING = [
    (re.compile(r"하여야"), "해야"),
    (re.compile(r"아니한"), "않은"),
    (re.compile(r"아니하"), "않"),
    (re.compile(r"[·ㆍ・]"), "ㆍ"),
    (re.compile(r"\s+"), " "),
]


# --- versions ----------------------------------------------------------------

def version_at(key, name, date):
    """The version of `name` in force on `date` (latest 시행일자 <= date)."""
    page = 1
    while True:
        data = clu.call(key, "lawSearch.do", target="eflaw", query=name,
                        display=clu.PAGE_SIZE, page=page, sort="efdes")
        rows = clu.as_list(data["LawSearch"].get("law"))
        for row in rows:
            if row["법령명한글"] == name and row["시행일자"] <= date:
                return row
        if len(rows) < clu.PAGE_SIZE:
            return None
        page += 1


def articles_of(key, version):
    """{'41': [...lines], '41의2': [...]} plus chapter headings, cached by MST + 시행일자."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache = CACHE_DIR / f"{version['법령ID']}_{version['법령일련번호']}_{version['시행일자']}.json"
    if cache.exists():
        units = json.loads(cache.read_text(encoding="utf-8"))
    else:
        law = clu.full_text(key, version)
        units = clu.as_list((law.get("조문") or {}).get("조문단위"))
        cache.write_text(json.dumps(units, ensure_ascii=False), encoding="utf-8")

    articles, toc = {}, []
    for unit in units:
        if unit.get("조문여부") == "전문":
            toc.append(("장", unit.get("조문내용", "").strip()))
            continue
        number = unit["조문번호"] + (f"의{unit['조문가지번호']}" if unit.get("조문가지번호") else "")
        articles[number] = [line for line in clu.render_articles([unit]) if line.strip()]
        toc.append((number, unit.get("조문제목", "")))
    return articles, toc


# --- article selection -------------------------------------------------------

def article_key(number):
    main, _, branch = number.partition("의")
    return int(main), int(branch or 0)


def label(number):
    main, _, branch = number.partition("의")
    return f"제{main}조" + (f"의{branch}" if branch else "")


def selected(spec, number):
    if spec is None:
        return True
    main, _ = article_key(number)
    for token in filter(None, (token.strip() for token in spec.split(","))):
        if "-" in token:
            low, high = token.split("-")
            if int(low) <= main <= int(high):
                return True
        elif token == number:
            return True
    return False


# --- diff --------------------------------------------------------------------

def normalize(line):
    line = ANNOTATIONS.sub("", line)
    for pattern, replacement in WORDING:
        line = pattern.sub(replacement, line)
    return line.strip()


def inline_diff(old, new):
    """Word-level diff: unchanged words plain, removals [-…-], additions {+…+}."""
    a, b = old.split(" "), new.split(" ")
    out = []
    for op, i1, i2, j1, j2 in difflib.SequenceMatcher(a=a, b=b, autojunk=False).get_opcodes():
        if op == "equal":
            words = a[i1:i2]
            out.append(" ".join(words) if len(words) <= 8 else f"{' '.join(words[:3])} … {' '.join(words[-3:])}")
        if op in ("delete", "replace"):
            out.append(f"[-{' '.join(a[i1:i2])}-]")
        if op in ("insert", "replace"):
            out.append(f"{{+{' '.join(b[j1:j2])}+}}")
    return " ".join(out)


def article_diff(old_lines, new_lines):
    old = [normalize(line) for line in old_lines]
    new = [normalize(line) for line in new_lines]
    if old == new:
        return []
    out = []
    matcher = difflib.SequenceMatcher(a=old, b=new, autojunk=False)
    for op, i1, i2, j1, j2 in matcher.get_opcodes():
        if op == "equal":
            continue
        if op == "replace" and i2 - i1 == j2 - j1:
            out.extend(f"  ~ {inline_diff(o, n)}" for o, n in zip(old[i1:i2], new[j1:j2]))
            continue
        out.extend(f"  - {line}" for line in old[i1:i2])
        out.extend(f"  + {line}" for line in new[j1:j2])
    return out


def law_diff(key, name, spec, date_from, date_to):
    old_version, new_version = version_at(key, name, date_from), version_at(key, name, date_to)
    if not new_version:
        return [f"## {name}: not found"]
    header = (f"## {name} — {clu.fmt(old_version['시행일자']) if old_version else '(없음)'} → "
              f"{clu.fmt(new_version['시행일자'])}" + ("" if spec is not None else "  ⚠ 조문 범위 미지정: 전체 비교"))
    if old_version and old_version["법령일련번호"] == new_version["법령일련번호"]:
        return [header, "변경 없음"]

    old_articles = articles_of(key, old_version)[0] if old_version else {}
    new_articles, _ = articles_of(key, new_version)
    out = [header]
    for number in sorted(set(old_articles) | set(new_articles), key=article_key):
        if not selected(spec, number):
            continue
        old, new = old_articles.get(number), new_articles.get(number)
        # Deleted articles stay in the text as "제N조 삭제 <…>"; treat that as removal.
        if new and len(new) == 1 and "삭제" in new[0] and old and "삭제" not in old[0]:
            out.append(f"{label(number)} 삭제 (구: {normalize(old[0])[:60]} …)")
            continue
        if not old:
            out.append(f"{label(number)} 신설")
            out.extend(f"  + {normalize(line)}" for line in new)
            continue
        if not new:
            out.append(f"{label(number)} 없어짐")
            continue
        changes = article_diff(old, new)
        if changes:
            out.append(normalize(new[0])[:40])
            out.extend(changes)
    if len(out) == 1:
        out.append("선택 조문 변경 없음 (정비성 개정만)")
    return out


# --- commands ----------------------------------------------------------------

def command_toc(key, args):
    version = version_at(key, args.law, args.to)
    if not version:
        sys.exit(f"{args.law}: not found")
    _, toc = articles_of(key, version)
    print(f"# {args.law} ({clu.fmt(version['시행일자'])})")
    row = []
    for number, title in toc:
        if number == "장":
            if row:
                print(" ".join(row))
                row = []
            print(f"\n{title}")
        else:
            row.append(f"{number}.{title}")
    if row:
        print(" ".join(row))


def command_article(key, args):
    version = version_at(key, args.law, args.at)
    if not version:
        sys.exit(f"{args.law}: not found")
    articles, _ = articles_of(key, version)
    print(f"# {args.law} ({clu.fmt(version['시행일자'])})")
    for number in args.numbers:
        lines = articles.get(number)
        print("\n".join(normalize(line) for line in lines) if lines else f"{label(number)}: 없음", end="\n\n")


def command_diff(key, args):
    laws = json.loads(clu.LAWS_FILE.read_text(encoding="utf-8"))["laws"]
    mapping = json.loads(PART_ARTICLES_FILE.read_text(encoding="utf-8")) if PART_ARTICLES_FILE.exists() else {}
    specs = mapping.get(str(args.part), {})
    names = [law["name"] for law in laws if args.part in law["parts"]]
    if args.law:
        names = [name for name in names if args.law in name]
    print(f"# part {args.part} 법령 변경 ({clu.fmt(args.date_from)} → {clu.fmt(args.to)})\n")
    for name in names:
        spec = specs.get(name)
        if spec == "":
            continue
        print("\n".join(law_diff(key, name, spec, args.date_from, args.to)), end="\n\n")
    missing = [name for name in names if name not in specs]
    if missing:
        print(f"⚠ part_articles.json에 part {args.part} 조문 범위 없음: {', '.join(missing)} "
              f"— `law_diff.py toc <법령명>`으로 고른 뒤 추가하면 출력이 줄어듦", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    toc = sub.add_parser("toc", help="list 장/조 titles of a law")
    toc.add_argument("law")
    toc.add_argument("--to", default=DEFAULT_TO, help="version in force on this date (YYYYMMDD)")
    diff = sub.add_parser("diff", help="net diff of the laws mapped to a part")
    diff.add_argument("--part", type=int, required=True)
    diff.add_argument("--law", help="only laws whose name contains this")
    diff.add_argument("--from", dest="date_from", default=DEFAULT_FROM, help="content last updated (YYYYMMDD)")
    diff.add_argument("--to", default=DEFAULT_TO, help="exam date (YYYYMMDD)")
    article = sub.add_parser("article", help="print articles of a law")
    article.add_argument("law")
    article.add_argument("numbers", nargs="+", help="article numbers, e.g. 41 41의2")
    article.add_argument("--at", default=DEFAULT_TO, help="version in force on this date (YYYYMMDD)")
    args = parser.parse_args()

    key = clu.load_key()
    {"toc": command_toc, "diff": command_diff, "article": command_article}[args.command](key, args)


if __name__ == "__main__":
    main()
