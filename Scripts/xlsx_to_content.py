#!/usr/bin/env python3
"""Convert realtornote.xlsx into the Resources/Content folder layout.

    Content/
    ├── manifest.json        version + subject order
    ├── subjects/{id}.json   subject outline: chapters → parts (order = array order)
    └── parts/{id}.txt       part body, plain text

Standard library only.

Usage:
    python3 Scripts/xlsx_to_content.py [xlsx] [out_dir]
"""

import json
import re
import shutil
import sys
import zipfile
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_XLSX = ROOT / "Projects/App/Resources/Excel/realtornote.xlsx"
DEFAULT_OUT = ROOT / "Projects/App/Resources/Content"

NS = {
    "m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}
HEADER_ROW = 2

# How the overflow cells (content → content2 → content3) join, keyed by (part id, boundary index).
# Excel split long parts at arbitrary points, so a raw join is not always right.
#   "\n"   → the split fell on a line break that was dropped
#   ""     → the split fell mid-line (raw join)
#   ("trim", n) → drop n trailing chars of the left cell (duplicated across the split)
# Any boundary not listed here fails the conversion, so new splits get reviewed by hand.
JOINS = {
    (9, 0): ("trim", 1),   # "…\nb" | "b) 민영주택" — "b" duplicated
    (10, 0): "\n",         # "…공중윤리" | "◎ 규제"
    (13, 0): "\n",         # "…(※ 암기법 : 비수)" | "13) 어업권"
    (28, 0): "\n",         # "…(2015년 개정 내용)" | "6) 보증금"
    (36, 0): "\n",         # "…과태료 500만원 이하" | "◎ 검인의제"
    (68, 0): "\n",         # "…지구단위계획구역 지정의 실효" | "- 고시일부터"
    (68, 1): "",           # "…출입한 자 " | ", 정비구역)" — REVIEW: text may be missing
    (70, 0): "\n",         # "…과태료 부과" | "7일 이내, …" — REVIEW: text may be missing
    (71, 0): "\n",         # "…5,000만원 이하 벌금" | "특별건축구역으로…"
    (72, 0): "",           # "…50제곱미터 " | "미만 주택은…"
}


def read_workbook(path):
    z = zipfile.ZipFile(path)
    shared = []
    if "xl/sharedStrings.xml" in z.namelist():
        for si in ET.fromstring(z.read("xl/sharedStrings.xml")).findall("m:si", NS):
            shared.append("".join(t.text or "" for t in si.iter(f"{{{NS['m']}}}t")))

    workbook = ET.fromstring(z.read("xl/workbook.xml"))
    rels = ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
    targets = {r.get("Id"): r.get("Target") for r in rels}

    sheets = {}
    for s in workbook.find("m:sheets", NS):
        target = targets[s.get(f"{{{NS['r']}}}id")].lstrip("/")
        target = target if target.startswith("xl/") else "xl/" + target
        rows = {}
        for row in ET.fromstring(z.read(target)).iter(f"{{{NS['m']}}}row"):
            cells = {}
            for c in row.findall("m:c", NS):
                column = re.match(r"[A-Z]+", c.get("r")).group()
                v = c.find("m:v", NS)
                inline = c.find("m:is", NS)
                if c.get("t") == "s" and v is not None:
                    cells[column] = shared[int(v.text)]
                elif inline is not None:
                    cells[column] = "".join(t.text or "" for t in inline.iter(f"{{{NS['m']}}}t"))
                else:
                    cells[column] = v.text if v is not None else ""
            rows[int(row.get("r"))] = cells
        sheets[s.get("name")] = rows
    return sheets


def records(sheet):
    """Rows below the header as {header name: value}, stopping at the first empty id."""
    header = sheet[HEADER_ROW]
    result = []
    for row_number in sorted(k for k in sheet if k > HEADER_ROW):
        row = {header[col]: value for col, value in sheet[row_number].items() if col in header}
        if not row.get("id"):
            break
        result.append(row)
    return result


def to_int(value):
    return int(float(value)) if value else 0


def join_content(part_id, cells):
    cells = [c for c in cells if c]
    text = cells[0] if cells else ""
    for index, right in enumerate(cells[1:]):
        key = (part_id, index)
        if key not in JOINS:
            sys.exit(f"part {part_id}: unreviewed split boundary {index} — add it to JOINS")
        rule = JOINS[key]
        if isinstance(rule, tuple):
            text = text[: -rule[1]] + right
        else:
            text = text + rule + right
    return text


def main():
    xlsx = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_XLSX
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUT

    sheets = read_workbook(xlsx)
    info = {row.get("B"): row.get("C", "") for row in sheets["info"].values() if row.get("B")}
    subjects = records(sheets["subjects"])
    chapters = records(sheets["chapters"])
    parts = records(sheets["parts"])

    chapters_by_subject = defaultdict(list)
    for c in chapters:
        chapters_by_subject[to_int(c["subject"])].append(c)
    parts_by_chapter = defaultdict(list)
    for p in parts:
        parts_by_chapter[to_int(p["chapter"])].append(p)

    # Validate before touching the output folder.
    part_ids = [to_int(p["id"]) for p in parts]
    assert len(part_ids) == len(set(part_ids)), "duplicate part id"
    chapter_ids = {to_int(c["id"]) for c in chapters}
    orphans = [p["id"] for p in parts if to_int(p["chapter"]) not in chapter_ids]
    assert not orphans, f"parts without chapter: {orphans}"
    used_keys = {(to_int(p["id"]), i) for p in parts
                 for i in range(sum(1 for f in ("content2", "content3") if p.get(f)))}
    stale = set(JOINS) - used_keys
    assert not stale, f"JOINS entries with no matching split: {sorted(stale)}"

    if out.exists():
        shutil.rmtree(out)
    (out / "subjects").mkdir(parents=True)
    (out / "parts").mkdir()

    def dump(path, value):
        path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    by_seq = lambda row: to_int(row["seq"])
    for s in subjects:
        subject_id = to_int(s["id"])
        outline = {
            "id": subject_id,
            "name": s.get("name", ""),
            # Header in the sheet is misspelled "detali".
            "detail": s.get("detail", s.get("detali", "")),
            "chapters": [
                {
                    "id": to_int(c["id"]),
                    "name": c.get("name", ""),
                    "parts": [
                        {"id": to_int(p["id"]), "name": p.get("name", "")}
                        for p in sorted(parts_by_chapter[to_int(c["id"])], key=by_seq)
                    ],
                }
                for c in sorted(chapters_by_subject[subject_id], key=by_seq)
            ],
        }
        dump(out / "subjects" / f"{subject_id}.json", outline)

    for p in parts:
        part_id = to_int(p["id"])
        content = join_content(part_id, [p.get("content", ""), p.get("content2", ""), p.get("content3", "")])
        (out / "parts" / f"{part_id}.txt").write_text(content, encoding="utf-8")

    dump(out / "manifest.json", {
        "version": info.get("version", "0.0"),
        "subjects": [to_int(s["id"]) for s in subjects],
    })

    print(f"{len(subjects)} subjects, {len(chapters)} chapters, {len(parts)} parts → {out}")


if __name__ == "__main__":
    main()
