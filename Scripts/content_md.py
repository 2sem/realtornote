#!/usr/bin/env python3
"""content_md.py - explicit-tree Markdown source for study-content parts.

The app shows each part (Projects/App/Resources/Content/parts/<id>.txt) through
LSDocumentRecognizer (Projects/App/Sources/Document/LSDocumentRecognizer.swift),
which rebuilds an outline tree from flat marker lines with a heuristic.  This
script ports that heuristic 1:1 and converts a part into a Markdown file whose
nested list *is* the tree, so the structure no longer depends on guessing.

Subcommands (all take a part id):
  tree <id> [--json]  tree the app builds today (port of recognize + parseType)
  render <id>         text the app displays      (port of toString)
  to-md <id>          txt -> ContentSource/parts/<id>.md
  from-md <id> [--json]  md -> tree (explicit structure, no heuristic)
  check <id>          tree(txt) == tree(md) node-for-node AND
                      render(md) == render(txt) byte-for-byte  -> OK / FAIL
  lint <id>|all       structural smells in the txt (line numbers + reasons)

Content is private (gitignored).  This file must never contain content text.

MARKDOWN RULES (ContentSource/parts/<id>.md)
------------------------------------------
* Optional first line: an HTML comment, e.g. `<!-- part 24 -->`.  Blank lines
  and further leading comments are ignored.
* One tree node per line: `<indent>- <marker> <text>`.
  indent = 2 spaces x tree depth (root nodes have no indent).  A line may be
  at most one level deeper than the line before it.
* Marker = the node's type, written with the number the app DISPLAYS (the
  index after the app's renumbering, not the raw number in the txt):
      (N)  brackets_number        N)  half_bracket_number
      x)   half_bracket_alpha     N.  number
      ◎    term                   ⇒   next
      >    untyped line (parser type `none`; text is the whole line,
           literal prefix kept: `- > * ...`, `- > (※ ...`, `- > 가) ...`)
      (no marker) dash (`- text`)
  Exactly one space separates marker and text; the rest of the line is the
  node text verbatim.
* Escape: a dash node whose text would itself read as a marker above (or
  that starts with a backslash) is written with a leading backslash:
  `- \\(1) ...`.  from-md strips exactly one leading backslash.
* The hidden index of unnumbered nodes (-, ◎, ⇒, >) is not stored; it is
  re-derived like the app does (0, +1 per directly preceding same-type line).
* Numbers in the md are authoritative for the tree index.  `lint` reports
  where the displayed number is not the node's ordinal among its siblings.
"""

import json
import os
import re
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PARTS_DIR = os.path.join(ROOT, "Projects", "App", "Resources", "Content", "parts")
MD_DIR = os.path.join(ROOT, "ContentSource", "parts")

# ---------------------------------------------------------------------------
# Character classes matching Foundation / ICU semantics
# ---------------------------------------------------------------------------
_Z = "".join(chr(c) for c in range(0x110000)
             if unicodedata.category(chr(c)) in ("Zs", "Zl", "Zp"))
_ZS = "".join(chr(c) for c in range(0x110000) if unicodedata.category(chr(c)) == "Zs")
# ICU regex \s = [\t\n\f\r\p{Z}]
ICU_S = "[\t\n\f\r" + re.escape(_Z) + "]"
ICU_NS = "[^\t\n\f\r" + re.escape(_Z) + "]"
# CharacterSet.whitespaces = Zs + U+0009
WHITESPACES = _ZS + "\t"
# CharacterSet.newlines = U+000A-U+000D, U+0085, U+2028, U+2029
NEWLINES_RE = re.compile("[\n\x0b\x0c\r\x85  ]")

NONE, NUMBER, BRACKETS, DASH, HALF, ALPHA, TERM, NEXT = (
    "none", "number", "brackets_number", "dash",
    "half_bracket_number", "half_bracket_alpha", "term", "next")

# IndexType raw values (Swift), \s / \S translated to ICU classes
RAW = {
    NUMBER: r"(?P<index>\d+)\.",
    BRACKETS: r"\((?P<index>\d+)\)",
    DASH: r"-",
    HALF: r"(?P<index>\d+)\)",
    ALPHA: r"(?P<index>" + ICU_NS + r")\)",
    TERM: "◎",
    NEXT: "⇒",
}
PARSE_ORDER = [NUMBER, BRACKETS, DASH, HALF, ALPHA, TERM, NEXT]
# "^\(rawValue)\\s*(?<text>[\\S\\s]+)$" with .dotMatchesLineSeparators
PATTERNS = {t: re.compile("^" + RAW[t] + ICU_S + r"*(?P<text>.+)$", re.S) for t in PARSE_ORDER}
INDEXING = (NUMBER, BRACKETS, HALF)
LOWER = "abcdefghijklmnopqrstuvwxyz"
UPPER = LOWER.upper()
INT_MAX = 2 ** 63 - 1


class RecognizerCrash(Exception):
    """A situation where the Swift code would trap (nil unwrap / bad index)."""


def swift_int(s):
    """Int(String) in Swift: ASCII digits only, nil on overflow -> caller uses 0."""
    if not s or not all("0" <= ch <= "9" for ch in s):
        return None
    v = int(s)
    return v if v <= INT_MAX else None


def int_alpha(s):
    """Int(alpha:) from LSExtensions: a-z -> 1..26, else A-Z -> 1..26, else 0."""
    if s in LOWER:
        return LOWER.index(s) + 1 if len(s) == 1 else 0
    if len(s) == 1 and s in UPPER:
        return UPPER.index(s) + 1
    return 0


def lower_alpha(i):
    """Int.lowerAlpha: list[i % 26 - 1]; Swift traps when i % 26 == 0."""
    k = i % 26 - 1
    if k < 0:
        raise RecognizerCrash("lowerAlpha of %d (index out of range)" % i)
    return LOWER[k]


def parse_type(string):
    """IndexType.parseType -> (type, index, text)."""
    for t in PARSE_ORDER:
        m = PATTERNS[t].match(string)
        if not m:
            continue
        text = m.group("text")
        index = 0
        if "index" in m.groupdict():            # keys.count > 2
            index = swift_int(m.group("index")) or 0
            if t == ALPHA:
                index = int_alpha(m.group("index"))
                if index == 0:
                    text = None
        if text is not None:
            return t, index, text
    return NONE, 0, string


def index_string(t, i):
    """IndexType.toIndexString."""
    if t == NUMBER:
        return "%d." % i
    if t == BRACKETS:
        return "(%d)" % i
    if t == HALF:
        return "%d)" % i
    if t == ALPHA:
        return lower_alpha(i) + ")"
    return {NONE: "", DASH: "-", TERM: "◎", NEXT: "⇒"}[t]


class Node:
    __slots__ = ("type", "index", "text", "parent", "children", "line", "raw", "branch")

    def __init__(self, t, index, text, line=0, raw=""):
        self.type, self.index, self.text = t, index, text
        self.parent, self.children = None, []
        self.line, self.raw, self.branch = line, raw, ""

    @property
    def level(self):
        return 0 if self.parent is None else 1 + self.parent.level

    def indexing_parent(self):
        n = self
        while n.type not in INDEXING:
            if n.parent is None:
                raise RecognizerCrash("indexingParent: no indexing ancestor (line %d)" % self.line)
            n = n.parent
        return n

    def find_parent(self, t):
        p = self.parent
        while p is not None:
            if p.type == t:
                return p
            p = p.parent
        return None

    def sibils_has_child(self):
        if self.parent is None:
            return False
        return any(s.children for s in self.parent.children if s is not self)

    def attach(self, parent):
        parent.children.append(self)
        self.parent = parent


def recognize(doc):
    """LSDocumentRecognizer.recognize(doc:). Each node gets .branch for lint."""
    values, before = [], None
    for lineno, line in enumerate(NEWLINES_RE.split(doc), 1):
        string = line.strip(WHITESPACES)
        if not string:
            continue
        t, idx, text = parse_type(string.strip(WHITESPACES))
        p = Node(t, idx, text, lineno, string)
        if before is not None:
            if before.type == p.type:
                p.index = before.index + 1
                p.branch = "same"
                if before.parent is not None:
                    p.attach(before.parent)
            else:
                sibil = before.find_parent(p.type)
                if sibil is not None:
                    if p.index == 1:
                        p.branch = "restart"
                        p.attach(before)
                    else:
                        p.branch = "ancestor"
                        if sibil.parent is not None:
                            p.attach(sibil.parent)
                elif p.type == TERM:
                    indexing_parent = before.indexing_parent()
                    sib = before.find_parent(p.type)   # always None here (checked above)
                    if sib is not None:
                        p.branch = "term:ancestor"
                        if sib.parent is not None:
                            p.attach(sib.parent)
                    elif indexing_parent is not before or before.parent is None:
                        p.branch = "term:indexing-parent"
                        p.attach(indexing_parent)
                    elif len(before.parent.children) > 1 and not before.sibils_has_child():
                        p.branch = "term:sibling-of-heading"
                        p.attach(before.parent)
                    else:
                        p.branch = "term:child-of-heading"
                        p.attach(before)
                else:
                    p.branch = "child"
                    p.attach(before)
        else:
            p.branch = "first"
        if p.parent is None:
            values.append(p)
        before = p
    return values


def walk(nodes):
    for n in nodes:
        yield n
        yield from walk(n.children)


def to_string(nodes, space=" "):
    """LSDocumentRecognizer.toString: pre-order, `space*level + marker + ' ' + text`."""
    return "\n".join(space * n.level + index_string(n.type, n.index) + " " + n.text
                     for n in walk(nodes))


def tree_json(nodes):
    return [{"type": n.type, "index": n.index, "text": n.text,
             "children": tree_json(n.children)} for n in nodes]


# ---------------------------------------------------------------------------
# Markdown
# ---------------------------------------------------------------------------
MD_MARKERS = [
    (BRACKETS, re.compile(r"^\((\d+)\) (.*)$", re.S)),
    (HALF, re.compile(r"^(\d+)\) (.*)$", re.S)),
    (ALPHA, re.compile(r"^([a-z])\) (.*)$", re.S)),
    (NUMBER, re.compile(r"^(\d+)\. (.*)$", re.S)),
    (TERM, re.compile(r"^◎ (.*)$", re.S)),
    (NEXT, re.compile(r"^⇒ (.*)$", re.S)),
    (NONE, re.compile(r"^> (.*)$", re.S)),
]


def md_parse_content(content):
    for t, rx in MD_MARKERS:
        m = rx.match(content)
        if m:
            if t in (BRACKETS, HALF, NUMBER):
                return t, int(m.group(1)), m.group(2)
            if t == ALPHA:
                return t, LOWER.index(m.group(1)) + 1, m.group(2)
            return t, 0, m.group(1)
    if content.startswith("\\"):
        return DASH, 0, content[1:]
    return DASH, 0, content


def md_content(n):
    t = n.type
    if t == DASH:
        if md_parse_content(n.text) != (DASH, 0, n.text):
            return "\\" + n.text
        return n.text
    if t == ALPHA:
        if not 1 <= n.index <= 26:
            raise ValueError("line %d: alpha index %d not representable" % (n.line, n.index))
        return LOWER[n.index - 1] + ") " + n.text
    if t == NONE:
        return "> " + n.text
    return index_string(t, n.index) + " " + n.text


def to_md(nodes, part_id):
    out = ["<!-- part %s -->" % part_id]
    for n in walk(nodes):
        out.append("  " * n.level + "- " + md_content(n))
    return "\n".join(out) + "\n"


def from_md(md):
    roots, stack = [], []          # stack[d] = last node at depth d
    started = False
    for lineno, line in enumerate(md.split("\n"), 1):
        if not line.strip():
            continue
        if not started and line.lstrip().startswith("<!--"):
            continue
        started = True
        spaces = len(line) - len(line.lstrip(" "))
        body = line[spaces:]
        if spaces % 2 or not body.startswith("- "):
            raise ValueError("md line %d: expected '<2n spaces>- ...'" % lineno)
        depth = spaces // 2
        if depth > len(stack):
            raise ValueError("md line %d: indent jumps more than one level" % lineno)
        t, idx, text = md_parse_content(body[2:])
        n = Node(t, idx, text, lineno)
        del stack[depth:]
        if depth == 0:
            roots.append(n)
        else:
            n.attach(stack[depth - 1])
        stack.append(n)
    # Unnumbered types carry a hidden index in the app (0, then +1 for each
    # directly preceding line of the same type).  Pre-order == line order, so
    # it is derived here instead of being stored in the md.
    prev = None
    for n in walk(roots):
        if n.type in (DASH, TERM, NEXT, NONE):
            n.index = prev.index + 1 if prev is not None and prev.type == n.type else 0
        prev = n
    return roots


# ---------------------------------------------------------------------------
# IO helpers
# ---------------------------------------------------------------------------
def read_txt(pid):
    with open(os.path.join(PARTS_DIR, "%s.txt" % pid), "rb") as f:
        return f.read().decode("utf-8")


def md_path(pid):
    return os.path.join(MD_DIR, "%s.md" % pid)


def all_ids():
    return sorted((int(f[:-4]) for f in os.listdir(PARTS_DIR) if f.endswith(".txt")))


def print_tree(nodes, as_json):
    if as_json:
        print(json.dumps(tree_json(nodes), ensure_ascii=False, indent=1))
        return
    for n in walk(nodes):
        print("%s[%s %d] %s" % ("  " * n.level, n.type, n.index, n.text))


# ---------------------------------------------------------------------------
# check
# ---------------------------------------------------------------------------
def first_tree_diff(a, b, path="root"):
    if len(a) != len(b):
        return "%s: child count %d (txt) vs %d (md)" % (path, len(a), len(b))
    for i, (x, y) in enumerate(zip(a, b)):
        p = "%s/%d" % (path, i)
        for attr in ("type", "index", "text"):
            if getattr(x, attr) != getattr(y, attr):
                return "%s (txt line %d, md line %d): %s %r vs %r" % (
                    p, x.line, y.line, attr, getattr(x, attr)[:30] if attr == "text" else getattr(x, attr),
                    getattr(y, attr)[:30] if attr == "text" else getattr(y, attr))
        d = first_tree_diff(x.children, y.children, p)
        if d:
            return d
    return None


def cmd_check(pid):
    txt_tree = recognize(read_txt(pid))
    with open(md_path(pid), encoding="utf-8") as f:
        md_tree = from_md(f.read())
    d = first_tree_diff(txt_tree, md_tree)
    if d:
        print("FAIL %s tree: %s" % (pid, d))
        return 1
    r1, r2 = to_string(txt_tree), to_string(md_tree)
    if r1.encode() != r2.encode():
        l1, l2 = r1.split("\n"), r2.split("\n")
        i = next((k for k in range(min(len(l1), len(l2))) if l1[k] != l2[k]), min(len(l1), len(l2)))
        print("FAIL %s render: first difference at rendered line %d" % (pid, i + 1))
        return 1
    print("OK %s  (%d nodes, render %d bytes identical)" % (pid, sum(1 for _ in walk(txt_tree)), len(r1.encode())))
    return 0


# ---------------------------------------------------------------------------
# lint
# ---------------------------------------------------------------------------
RANK = {BRACKETS: 1, HALF: 2, ALPHA: 3}
INLINE_ENUM = re.compile(r"(?:^|\s)(\(\d+\)|\d+\)|[a-zA-Z]\))\s*\S")
SMELLS = ["jump", "inverted", "buried", "term?", "restart", "inline", "inline⇒", "untyped",
          "numbering", "dup", "parser-bug", "crash"]


def snippet(s):
    s = s.replace("\t", " ")
    return s if len(s) <= 30 else s[:30] + "…"


def lint(pid):
    """Returns list of (smell, line, reason, snippet)."""
    doc = read_txt(pid)
    out = []
    try:
        roots = recognize(doc)
    except RecognizerCrash as e:
        return [("crash", 0, "Swift parser would trap: %s" % e, "")]

    nodes = list(walk(roots))
    for n in nodes:
        # level jumps / inversions among (1) > 1) > a)
        if n.type in RANK:
            anc = n.parent
            while anc is not None and anc.type not in RANK:
                anc = anc.parent
            r, ar = RANK[n.type], (RANK[anc.type] if anc else 0)
            if ar < r - 1:
                out.append(("jump", n.line, "%s under %s" % (
                    index_string(n.type, n.index) if n.type != ALPHA or n.index % 26 else n.type,
                    index_string(anc.type, anc.index) if anc else "root"), snippet(n.raw)))
            elif anc is not None and ar >= r:
                out.append(("inverted", n.line, "%s nested under %s" % (
                    n.type, anc.type), snippet(n.raw)))
        # heading buried under a non-heading line (-, ◎, ⇒, untyped)
        # (a) under ◎ is the normal "◎ heading / a) b) c)" pattern and is not flagged)
        if n.type in RANK and n.parent is not None and (
                n.parent.type in (DASH, NEXT, NONE) or (n.parent.type == TERM and n.type != ALPHA)):
            out.append(("buried", n.line, "%s is a child of a '%s' line" % (
                n.type, index_string(n.parent.type, 0) or "untyped"), snippet(n.raw)))
        # term placement
        prev_line = nodes[nodes.index(n) - 1] if nodes.index(n) > 0 else None
        if (n.type == TERM and n.branch == "ancestor" and prev_line is not None
                and prev_line.type in INDEXING and prev_line.parent is not None
                and prev_line.parent.type in (DASH, NEXT, NONE)):
            out.append(("term?", n.line, "◎ right after heading %s joins an earlier ◎ level "
                        "instead of becoming its child" % prev_line.type, snippet(n.raw)))
        if n.type == TERM and n.branch.startswith("term:"):
            reason = None
            if n.branch == "term:sibling-of-heading":
                reason = "◎ made sibling of the heading above it (not its child)"
            elif n.branch == "term:indexing-parent":
                # distance climbed from the previous line to the new parent
                prev = nodes[nodes.index(n) - 1]
                climb = prev.level - n.parent.level
                if climb >= 2:
                    reason = "◎ climbed %d levels to %s" % (climb, index_string(n.parent.type, n.parent.index))
            if reason:
                out.append(("term?", n.line, reason, snippet(n.raw)))
        if n.branch == "restart":
            out.append(("restart", n.line, "%s restarts at 1 -> child of previous line" % n.type, snippet(n.raw)))
        # inline items
        body = n.text if n.type != NONE else n.text
        m = INLINE_ENUM.search(body)
        if m or ("◎" in body):
            what = m.group(1) if m else "◎"
            out.append(("inline", n.line, "another item marker '%s' inside the line%s" % (
                what, " (with ⇒)" if "⇒" in body else ""), snippet(n.raw)))
        elif "⇒" in body and n.type != NEXT:
            out.append(("inline⇒", n.line, "⇒ mid-line", snippet(n.raw)))
        elif "⇒" in body:
            out.append(("inline⇒", n.line, "second ⇒ inside a ⇒ line", snippet(n.raw)))
        # untyped
        if n.type == NONE:
            raw = n.raw
            if raw.startswith("*"):
                kind = "'*' prefix"
            elif raw.startswith("(※") or raw.startswith("※"):
                kind = "'※' note"
            elif re.match(r"^\S\)", raw):
                kind = "non-latin enumerator %r" % raw[:2]
            else:
                kind = "plain text"
            out.append(("untyped", n.line, kind + (" (has children)" if n.children else ""), snippet(raw)))
        # parser bugs visible in this content
        if n.type == NUMBER and re.match(r"^\d+\.\d", n.raw):
            out.append(("parser-bug", n.line, "decimal number read as '1.' item", snippet(n.raw)))
        if n.type == ALPHA and n.raw[0] in UPPER:
            out.append(("parser-bug", n.line, "uppercase alpha shown as lowercase", snippet(n.raw)))
        if any(ord(ch) > 0xFFFF or unicodedata.category(ch) in ("Mn", "Me", "Mc", "Cf") for ch in n.raw):
            out.append(("parser-bug", n.line, "String.fullRange uses grapheme count; "
                        "text may be cut (not emulated here)", snippet(n.raw)))
        if n.type == ALPHA and n.index % 26 == 0:
            out.append(("crash", n.line, "alpha index %d -> lowerAlpha traps" % n.index, snippet(n.raw)))
    # displayed number vs ordinal among same-type siblings
    for parent_children in [roots] + [n.children for n in nodes]:
        count = {}
        for c in parent_children:
            if c.type in (BRACKETS, HALF, ALPHA, NUMBER):
                count[c.type] = count.get(c.type, 0) + 1
                if c.index != count[c.type]:
                    out.append(("numbering", c.line, "shows %s but is sibling #%d" % (
                        index_string(c.type, c.index) if c.type != ALPHA or c.index % 26 else c.index,
                        count[c.type]), snippet(c.raw)))
    # verbatim duplicated blocks (>= 3 consecutive lines)
    lines = [(i, l.strip(WHITESPACES)) for i, l in enumerate(NEWLINES_RE.split(doc), 1)]
    lines = [x for x in lines if x[1]]
    txts = [l for _, l in lines]
    for i in range(len(txts)):
        for j in range(i + 1, len(txts)):
            if txts[i] != txts[j] or (i > 0 and txts[i - 1] == txts[j - 1]):
                continue
            k = 0
            while j + k < len(txts) and i + k < j and txts[i + k] == txts[j + k]:
                k += 1
            if k >= 3:
                out.append(("dup", lines[j][0], "%d lines repeat lines %d-%d" % (
                    k, lines[i][0], lines[i + k - 1][0]), snippet(txts[j])))
    out.sort(key=lambda x: (x[1], x[0]))
    return out


def cmd_lint(arg):
    if arg == "all":
        print("part | " + " | ".join(SMELLS))
        print("---|" + "|".join("---" for _ in SMELLS))
        totals = dict.fromkeys(SMELLS, 0)
        for pid in all_ids():
            c = dict.fromkeys(SMELLS, 0)
            for s, *_ in lint(pid):
                c[s] += 1
                totals[s] += 1
            print("%d | %s" % (pid, " | ".join(str(c[s]) for s in SMELLS)))
        print("total | " + " | ".join(str(totals[s]) for s in SMELLS))
        return 0
    for s, line, reason, snip in lint(arg):
        print("%5d  %-10s %s  | %s" % (line, s, reason, snip))
    return 0


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    cmd, pid = argv[1], argv[2]
    as_json = "--json" in argv
    try:
        if cmd == "tree":
            print_tree(recognize(read_txt(pid)), as_json)
        elif cmd == "render":
            sys.stdout.write(to_string(recognize(read_txt(pid))) + "\n")
        elif cmd == "to-md":
            md = to_md(recognize(read_txt(pid)), pid)
            os.makedirs(MD_DIR, exist_ok=True)
            with open(md_path(pid), "w", encoding="utf-8") as f:
                f.write(md)
            print("wrote %s" % os.path.relpath(md_path(pid), ROOT))
        elif cmd == "from-md":
            with open(md_path(pid), encoding="utf-8") as f:
                print_tree(from_md(f.read()), as_json)
        elif cmd == "check":
            return cmd_check(pid)
        elif cmd == "lint":
            return cmd_lint(pid)
        else:
            print(__doc__)
            return 2
    except RecognizerCrash as e:
        print("CRASH (Swift would trap): %s" % e)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
