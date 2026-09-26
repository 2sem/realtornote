#!/usr/bin/env python3
"""Verify Resources/Content against realtornote.xlsx, field by field.

Independent of the conversion's output logic: rebuilds the expected tree from
the xlsx and compares it with what is on disk. Exits non-zero on any mismatch.

Usage:
    python3 Scripts/verify_content.py [xlsx] [content_dir]
"""

import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import xlsx_to_content as conv  # noqa: E402  (reuses only the xlsx reader and JOINS table)

xlsx = Path(sys.argv[1]) if len(sys.argv) > 1 else conv.DEFAULT_XLSX
root = Path(sys.argv[2]) if len(sys.argv) > 2 else conv.DEFAULT_OUT

errors = []
def check(ok, message):
    if not ok:
        errors.append(message)

sheets = conv.read_workbook(xlsx)
subjects = conv.records(sheets["subjects"])
chapters = conv.records(sheets["chapters"])
parts = conv.records(sheets["parts"])
n = conv.to_int

# Rows after the first blank id would be silently dropped — make sure there are none.
for name in ("subjects", "chapters", "parts"):
    with_id = [k for k, r in sheets[name].items() if k > conv.HEADER_ROW and r.get("B")]
    check(len(with_id) == len(conv.records(sheets[name])), f"{name}: rows after a blank id")

# manifest
manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
version = next(r.get("C") for r in sheets["info"].values() if r.get("B") == "version")
check(manifest["version"] == version, f"version {manifest['version']} != {version}")
check(manifest["subjects"] == [n(s["id"]) for s in subjects], "subject order")

# outline: every subject / chapter / part, name, parent and order
seen_parts = set()
for s in subjects:
    sid = n(s["id"])
    outline = json.loads((root / "subjects" / f"{sid}.json").read_text(encoding="utf-8"))
    check(outline["id"] == sid, f"subject {sid}: id")
    check(outline["name"] == s.get("name", ""), f"subject {sid}: name")

    xl_chapters = sorted((c for c in chapters if n(c["subject"]) == sid), key=lambda c: n(c["seq"]))
    check([c["id"] for c in outline["chapters"]] == [n(c["id"]) for c in xl_chapters],
          f"subject {sid}: chapter ids/order")
    for seq, (c, xc) in enumerate(zip(outline["chapters"], xl_chapters), start=1):
        check(n(xc["seq"]) == seq, f"chapter {c['id']}: seq {xc['seq']} != position {seq}")
        check(c["name"] == xc.get("name", ""), f"chapter {c['id']}: name")

        xl_parts = sorted((p for p in parts if n(p["chapter"]) == c["id"]), key=lambda p: n(p["seq"]))
        check([p["id"] for p in c["parts"]] == [n(p["id"]) for p in xl_parts],
              f"chapter {c['id']}: part ids/order")
        for pseq, (p, xp) in enumerate(zip(c["parts"], xl_parts), start=1):
            check(n(xp["seq"]) == pseq, f"part {p['id']}: seq {xp['seq']} != position {pseq}")
            check(p["name"] == xp.get("name", ""), f"part {p['id']}: name")
            seen_parts.add(p["id"])

check(seen_parts == {n(p["id"]) for p in parts}, "outline part set != xlsx part set")
check(len(list((root / "subjects").glob("*.json"))) == len(subjects), "extra subject files")

# part bodies
files = {int(f.stem) for f in (root / "parts").glob("*.txt")}
check(files == {n(p["id"]) for p in parts}, f"part files mismatch: {sorted(files ^ {n(p['id']) for p in parts})}")

exact, split = 0, []
for p in parts:
    pid = n(p["id"])
    if pid not in files:
        continue  # already reported above
    body = (root / "parts" / f"{pid}.txt").read_text(encoding="utf-8")
    cells = [p.get(f, "") for f in ("content", "content2", "content3") if p.get(f)]

    if len(cells) == 1:
        check(body == cells[0], f"part {pid}: content differs from xlsx")
        exact += 1
        continue

    # Split part: every cell must appear in order, and only the reviewed JOINS may differ.
    cursor = 0
    for i, cell in enumerate(cells):
        rule = conv.JOINS.get((pid, i))
        piece = cell[: -rule[1]] if isinstance(rule, tuple) else cell
        at = body.find(piece, cursor)
        check(at == cursor, f"part {pid}: cell {i + 1} not found at {cursor} (found at {at})")
        cursor = at + len(piece)
        if isinstance(rule, str):
            check(body[cursor:cursor + len(rule)] == rule, f"part {pid}: join {i} != {rule!r}")
            cursor += len(rule)
    check(cursor == len(body), f"part {pid}: {len(body) - cursor} trailing chars not from xlsx")
    split.append((pid, sum(map(len, cells)), len(body)))

print(f"subjects {len(subjects)}, chapters {len(chapters)}, parts {len(parts)}")
print(f"parts identical to xlsx cell: {exact}")
for pid, cells_len, body_len in split:
    print(f"split part {pid}: cells {cells_len} chars → file {body_len} chars (Δ {body_len - cells_len:+d}, reviewed joins)")

if errors:
    print(f"\nFAILED — {len(errors)} mismatch(es):")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("\nOK — Content matches xlsx")
