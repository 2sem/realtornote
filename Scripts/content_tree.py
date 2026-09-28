#!/usr/bin/env python3
"""content_tree.py - semantic Markdown source -> JSON content tree (plan P1).

See docs/plans/content-tree.md.  Stdlib only; reuses the 1:1 port of the app
parser in content_md.py (recognize / to_string / lint).

Subcommands:
  migrate <id>|all          old tree (txt, app heuristic) -> ContentSource/parts/<id>.md
  build <id>|all [--strict] ContentSource/parts/<id>.md -> ContentSource/build/parts/<id>.json
                            (TODOs are warnings; --strict fails while any remain)
  render-a <id>             JSON -> Phase A text (same format as the app's toString)
  parity <id>|all [--fresh] render-a(build(md)) vs render(txt), byte-for-byte.
                            Uses ContentSource/parts/<id>.md when it exists, else (or
                            with --fresh) migrates in memory without writing anything.
  todos <id>|all            TODO counts per smell in ContentSource/parts/<id>.md

Content is private (gitignored).  This file must never contain content text.

MARKDOWN (ContentSource/parts/<id>.md) - one node per line
----------------------------------------------------------
  # title          section depth 0   Phase A `N.`   (chapter; only parts 6-10)
  ## title         section depth 1   Phase A `(N)`
  ### title        section depth 2   Phase A `N)`
  #### title       section depth 3   Phase A `a)`
  plain line       section summary; only directly under a heading.
                   Phase A: `title - summary`
  - **label**: text  term with text       `◎ label : text`
  - **label**        term (children follow)  `◎ label`
  - text             item                 `- text`
  - → text           item role then       `⇒ text`
  - ~ text           item role raw        literal text, no marker (untyped line
                                          the migration could not type; TODO)
  - \\text           item whose text starts with a syntax char (`**`, `→ `,
                     `~ `, `#`, `\\`) - one leading backslash is stripped
  N. text            ordered list item    `a)`, `b)` ... (N = letter shown)
  > 암기법: text     note mnemonic        `(※ 암기법 : text)`
  > 참고: text       note tip             `* text`
  > 공식: text       note formula         `* text`
  | a | b |          table (not produced by migrate; no Phase A text yet)

  Headings live at column 0 only.  Everything else is a list line indented
  2 spaces per nesting level; indent 0 = child of the innermost open heading
  (or of the part root before the first heading).  A list line may be at most
  one level deeper than the previous list line.

  Structure escape hatches (only needed while a part still has TODOs):
  - `- ## title` etc.   a section that sits inside a list (old `buried` /
                        `inverted` / `restart` trees).  Needs a TODO above it.
  - skipped heading level (`###` right under root/`#`, old `jump`).  Needs a TODO.
  - `<!-- /### -->`     close marker: closes every open heading of that level
                        or deeper, so following lines belong to the parent
                        section again (old tree: content after a sub-section).
  - ` <!-- n=K -->`     at the end of a heading line: the number shown is K,
                        not the natural next number (old `numbering`).
  - ordered items: the Markdown number IS the number shown; build stores
    `start` / per-item `n` only where it isn't the natural sequence.

  `<!-- TODO(<smell>): reason -->` on its own line refers to the next node.
  `<!-- ... -->` lines are otherwise ignored.

JSON (ContentSource/build/parts/<id>.json)
------------------------------------------
  {"part": id, "nodes": [node...]}
  section {type, title, summary?, depth?, n?, children?}
          depth only when it differs from nesting (nearest section ancestor + 1,
          root -> 1); n only when it isn't previous same-depth sibling + 1.
  term    {type, label, text?, children?}
  list    {type, ordered: true, start?, items: [{text, n?, children?}]}
  item    {type, text, role? ("then" | "raw"), children?}
  note    {type, kind ("mnemonic" | "tip" | "formula"), text}
  table   {type, header, rows}

MIGRATE MAPPING (deterministic)
-------------------------------
  N. / (N) / N)  -> # / ## / ### heading when the tree position allows it
                   (deeper than the parent heading), else `- ##` inside the list
  a)             -> #### heading when its parent is a `###` heading AND any a)
                   sibling under that parent has children (whole group becomes
                   headings); otherwise an ordered list item `N.`
  heading `X - Y`-> title X + summary Y when unambiguous: exactly one ` - `,
                   1-20 char title, summary not starting with syntax chars
  ◎ X : Y        -> `- **X**: Y` (only the exact ` : ` separator; `X - Y`,
                   `X: Y`, `X :` stay whole in the label so Phase A is unchanged)
  -  / ⇒         -> `- text` / `- → text`
  * text         -> `> 공식:` if it contains `=`, else `> 참고:` (exact `* ` only,
                   no children)
  (※ 암기법 : X) -> `> 암기법: X` (exact literal only, no children)
  other untyped  -> `- ~ literal` + TODO(untyped)
  every node lint flags gets `<!-- TODO(<smell>): <reason> -->` above it
  (except `untyped` on lines that became notes - they are typed now);
  content after a sub-section gets TODO(trailing) + a close marker.
"""

import json
import os
import re
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import content_md as cm  # noqa: E402
from content_md import (NONE, NUMBER, BRACKETS, DASH, HALF, ALPHA, TERM, NEXT,  # noqa: E402
                        LOWER, RecognizerCrash)

ROOT = cm.ROOT
SRC_DIR = os.path.join(ROOT, "ContentSource", "parts")
BUILD_DIR = os.path.join(ROOT, "ContentSource", "build", "parts")

HEADING_LEVEL = {NUMBER: 1, BRACKETS: 2, HALF: 3, ALPHA: 4}     # md `#` count
SECTION_TYPES = (NUMBER, BRACKETS, HALF)
NOTE_KIND = {"암기법": "mnemonic", "참고": "tip", "공식": "formula"}
KIND_LABEL = {v: k for k, v in NOTE_KIND.items()}
MNEMONIC_RE = re.compile(r"^\(※ 암기법 : (.+)\)$", re.S)
TIP_RE = re.compile(r"^\* (\S.*)$", re.S)
ESCAPE_RE = re.compile(r"^(\*\*|→ |~ |#|\\)")
SUMMARY_BAD_START = re.compile(r"^(\s|[-#>|<\\*~]|\d+\. )")


class BuildError(Exception):
    pass


def src_path(pid):
    return os.path.join(SRC_DIR, "%s.md" % pid)


def build_path(pid):
    return os.path.join(BUILD_DIR, "%s.json" % pid)


# ===========================================================================
# migrate: old tree -> new Markdown
# ===========================================================================
def split_summary(text):
    if text.count(" - ") != 1:
        return text, None
    title, summary = text.split(" - ")
    if not (1 <= len(title) <= 20) or title != title.strip() or not summary:
        return text, None
    if SUMMARY_BAD_START.match(summary):
        return text, None
    return title, summary


def term_line(text):
    if " : " in text:
        label, rest = text.split(" : ", 1)
        if label and rest and "**" not in label:
            return "**%s**: %s" % (label, rest)
    return "**%s**" % text


def item_text(text):
    return "\\" + text if ESCAPE_RE.match(text) else text


class Migrator:
    def __init__(self, pid):
        self.pid = pid
        roots = cm.recognize(cm.read_txt(pid))
        self.roots = roots
        self.smells = {}
        for smell, line, reason, _ in cm.lint(pid):
            self.smells.setdefault(line, []).append((smell, reason))
        self.out = ["<!-- part %s -->" % pid]
        self.todo_count = Counter()

    # -- helpers ------------------------------------------------------------
    def todo(self, indent, smell, reason):
        self.out.append("  " * indent + "<!-- TODO(%s): %s -->" % (smell, reason))
        self.todo_count[smell] += 1

    def node_todos(self, n, indent, skip=()):
        smells = [s for s in self.smells.get(n.line, []) if s[0] not in skip]
        for smell, reason in smells:
            self.todo(indent, smell, reason)
        return bool(smells)

    @staticmethod
    def expected_numbers(siblings, is_section):
        """Displayed number the renderer derives for each section sibling."""
        exp, last = {}, {}
        for s in siblings:
            if is_section(s):
                exp[id(s)] = last.get(s.type, 0) + 1
                last[s.type] = s.index
        return exp

    def n_suffix(self, n, exp):
        return "" if exp.get(id(n)) == n.index else " <!-- n=%d -->" % n.index

    # -- heading context ------------------------------------------------------
    def heading_ctx(self, children, hp, alpha_mode):
        is_sec = (lambda s: s.type in SECTION_TYPES or (s.type == ALPHA and alpha_mode))
        exp = self.expected_numbers(children, is_sec)
        last_level = None
        for c in children:
            lvl = HEADING_LEVEL.get(c.type)
            heading_able = (lvl is not None and lvl > hp
                            and (c.type != ALPHA or alpha_mode))
            if heading_able:
                if last_level is not None and lvl > last_level:
                    self.out.append("<!-- /%s -->" % ("#" * (hp + 1)))
                self.node_todos(c, 0)
                title, summary = split_summary(c.text)
                self.out.append("%s %s%s" % ("#" * lvl, title, self.n_suffix(c, exp)))
                if summary is not None:
                    self.out.append(summary)
                child_alpha = (c.type == HALF and
                               any(k.children for k in c.children if k.type == ALPHA))
                self.heading_ctx(c.children, lvl, child_alpha)
                last_level = lvl
            else:
                if last_level is not None:
                    self.out.append("<!-- /%s -->" % ("#" * (hp + 1)))
                    self.todo(0, "trailing", "belongs to the parent section, after a sub-section")
                    last_level = None
                self.list_node(c, 0, exp)

    # -- list context ---------------------------------------------------------
    def list_node(self, n, indent, exp, alpha_list=True):
        pad = "  " * indent
        t = n.type
        # an untyped `*` / `(※ 암기법 : …)` line that becomes a note is typed now
        is_note = t == NONE and not n.children and bool(
            MNEMONIC_RE.match(n.text) or TIP_RE.match(n.text))
        flagged = self.node_todos(n, indent, skip=("untyped",) if is_note else ())
        if t in SECTION_TYPES or (t == ALPHA and not alpha_list):
            if not flagged:
                self.todo(indent, "buried", "heading marker inside a list")
            self.out.append("%s- %s %s%s" % (pad, "#" * HEADING_LEVEL[t], n.text, self.n_suffix(n, exp)))
        elif t == ALPHA:
            self.out.append("%s%d. %s" % (pad, n.index, n.text))
        elif t == TERM:
            self.out.append("%s- %s" % (pad, term_line(n.text)))
        elif t == DASH:
            self.out.append("%s- %s" % (pad, item_text(n.text)))
        elif t == NEXT:
            self.out.append("%s- → %s" % (pad, n.text))
        elif t == NONE:
            m1, m2 = MNEMONIC_RE.match(n.text), TIP_RE.match(n.text)
            if not n.children and m1:
                self.out.append("%s> 암기법: %s" % (pad, m1.group(1)))
            elif not n.children and m2:
                kind = "공식" if "=" in m2.group(1) else "참고"
                self.out.append("%s> %s: %s" % (pad, kind, m2.group(1)))
            else:
                if not flagged:
                    self.todo(indent, "untyped", "untyped line kept literally")
                self.out.append("%s- ~ %s" % (pad, n.text))
        else:
            raise ValueError("unknown type %s" % t)
        cexp = self.expected_numbers(n.children, lambda s: s.type in SECTION_TYPES)
        for c in n.children:
            self.list_node(c, indent + 1, cexp)

    def run(self):
        self.heading_ctx(self.roots, 0, False)
        return "\n".join(self.out) + "\n"


def migrate(pid):
    m = Migrator(pid)
    return m.run(), m.todo_count


# ===========================================================================
# build: new Markdown -> JSON
# ===========================================================================
HEADING_RE = re.compile(r"^(#{1,4}) (.*?)(?: <!-- n=(\d+) -->)?$", re.S)
ORDERED_RE = re.compile(r"^(\d+)\. (.*)$", re.S)
NOTE_RE = re.compile(r"^> (암기법|참고|공식): (.*)$", re.S)
TERM_TEXT_RE = re.compile(r"^\*\*(.+?)\*\*: (.*)$", re.S)
TERM_ONLY_RE = re.compile(r"^\*\*(.+)\*\*$", re.S)
TODO_RE = re.compile(r"^<!-- TODO(?:\(([^)]*)\))?:? ?(.*?) ?-->$")
CLOSE_RE = re.compile(r"^<!-- /(#{1,4}) -->$")


def _section_depth_natural(ancestors):
    for a in reversed(ancestors):
        if a["type"] == "section":
            return a.get("depth", a["_nat"]) + 1
    return 1


def parse_md(md, pid="?"):
    """Returns (nodes, todos, warnings).  Raises BuildError on rule violations."""
    roots = []
    headings = []          # stack of (level, section)
    lstack = []            # list-context stack: lstack[d] = node at indent d
    todos, warnings = [], []
    pending = []           # TODO comments waiting for their node
    summary_ok = None      # section expecting a summary line
    root_like = {"type": "root", "children": roots}

    def err(lineno, msg):
        raise BuildError("part %s line %d: %s" % (pid, lineno, msg))

    def heading_container():
        return headings[-1][1] if headings else root_like

    def attach(container, node):
        ch = container.setdefault("children", [])
        ch.append(node)

    def attach_ordered(container, item, number):
        ch = container.setdefault("children", [])
        if ch and ch[-1]["type"] == "list" and ch[-1].get("_open"):
            lst = ch[-1]
        else:
            if ch and ch[-1]["type"] == "list":
                ch[-1]["_open"] = False
            lst = {"type": "list", "ordered": True, "items": [], "_open": True, "_prev": number - 1}
            if number != 1:
                lst["start"] = number
            ch.append(lst)
        if number != lst["_prev"] + 1:
            item["n"] = number
        lst["_prev"] = number
        lst["items"].append(item)

    def close_lists(container):
        ch = container.get("children") or []
        if ch and ch[-1]["type"] == "list":
            ch[-1]["_open"] = False

    for lineno, line in enumerate(md.split("\n"), 1):
        if not line.strip():
            continue
        stripped = line.strip(" ")
        if stripped.startswith("<!--") and stripped.endswith("-->"):
            m = CLOSE_RE.match(stripped)
            if m:
                lvl = len(m.group(1))
                if not any(h[0] >= lvl for h in headings):
                    err(lineno, "close marker %s but no such heading is open" % m.group(1))
                headings = [h for h in headings if h[0] < lvl]
                lstack = []
                summary_ok = None
                continue
            m = TODO_RE.match(stripped)
            if m:
                pending.append((lineno, m.group(1) or "", m.group(2)))
            continue
        if "\t" in line[:len(line) - len(line.lstrip(" \t"))]:
            err(lineno, "tab in indentation")
        spaces = len(line) - len(line.lstrip(" "))
        body = line[spaces:]
        node_todos, pending = pending, []
        for t in node_todos:
            todos.append(t)

        # ---- headings -------------------------------------------------
        m = HEADING_RE.match(body)
        if m and body.startswith("#"):
            if spaces:
                err(lineno, "heading inside a list (indented heading)")
            lvl = len(m.group(1))
            while headings and headings[-1][0] >= lvl:
                headings.pop()
            parent_lvl = headings[-1][0] if headings else 0
            if lvl > max(parent_lvl, 1) + 1:
                if not node_todos:
                    err(lineno, "skipped heading level (%s under %s)" % (
                        "#" * lvl, "#" * parent_lvl or "root"))
                warnings.append("line %d: skipped heading level (TODO)" % lineno)
            container = heading_container()
            close_lists(container)
            nat = _section_depth_natural([h[1] for h in headings])
            sec = {"type": "section", "title": m.group(2), "_nat": nat, "_line": lineno}
            if lvl - 1 != nat:
                sec["depth"] = lvl - 1
            if m.group(3) is not None:
                sec["_n"] = int(m.group(3))
            attach(container, sec)
            headings.append((lvl, sec))
            lstack = []
            summary_ok = sec
            continue

        # ---- summary ----------------------------------------------------
        is_list_line = (body.startswith("- ") or body == "-" or ORDERED_RE.match(body)
                        or body.startswith("> ") or body.startswith("|"))
        if not is_list_line:
            if spaces == 0 and summary_ok is not None and not node_todos:
                summary_ok["summary"] = body
                summary_ok = None
                continue
            err(lineno, "plain text line is only allowed as a summary right under a heading")
        summary_ok = None

        # ---- list lines ------------------------------------------------
        if spaces % 2:
            err(lineno, "indentation must be a multiple of 2 spaces")
        depth = spaces // 2
        if depth > len(lstack):
            err(lineno, "indent jumps more than one level")
        del lstack[depth:]
        container = heading_container() if depth == 0 else lstack[depth - 1]
        ancestors = [h[1] for h in headings] + lstack[:depth]

        m = ORDERED_RE.match(body)
        if m:
            node = {"type": "_item", "text": m.group(2), "_line": lineno}
            attach_ordered(container, node, int(m.group(1)))
            lstack.append(node)
            continue
        close_lists(container)
        if body.startswith("|"):
            cells = [c.strip() for c in body.strip().strip("|").split("|")]
            ch = container.setdefault("children", [])
            if ch and ch[-1]["type"] == "table" and ch[-1].get("_open"):
                tbl = ch[-1]
                if all(re.match(r"^:?-+:?$", c) for c in cells):
                    continue
                tbl["rows"].append(cells)
            else:
                tbl = {"type": "table", "header": cells, "rows": [], "_open": True}
                ch.append(tbl)
            lstack.append(tbl)
            continue
        if body.startswith("> "):
            m = NOTE_RE.match(body)
            if not m:
                err(lineno, "note must be `> 암기법:`, `> 참고:` or `> 공식:`")
            node = {"type": "note", "kind": NOTE_KIND[m.group(1)], "text": m.group(2)}
            attach(container, node)
            lstack.append(node)
            continue
        content = body[2:]
        mh = HEADING_RE.match(content)
        if mh and content.startswith("#"):
            if not node_todos:
                err(lineno, "heading inside a list (needs a TODO while migrating)")
            warnings.append("line %d: heading inside a list (TODO)" % lineno)
            lvl = len(mh.group(1))
            nat = _section_depth_natural(ancestors)
            node = {"type": "section", "title": mh.group(2), "_nat": nat, "_line": lineno}
            if lvl - 1 != nat:
                node["depth"] = lvl - 1
            if mh.group(3) is not None:
                node["_n"] = int(mh.group(3))
        elif content.startswith("**"):
            mt = TERM_TEXT_RE.match(content)
            if mt:
                node = {"type": "term", "label": mt.group(1), "text": mt.group(2)}
            else:
                mo = TERM_ONLY_RE.match(content)
                if not mo:
                    err(lineno, "term must be `- **label**` or `- **label**: text`")
                node = {"type": "term", "label": mo.group(1)}
        elif content.startswith("→ "):
            node = {"type": "item", "text": content[2:], "role": "then"}
        elif content.startswith("~ "):
            node = {"type": "item", "text": content[2:], "role": "raw"}
        elif content.startswith("\\"):
            node = {"type": "item", "text": content[1:]}
        else:
            node = {"type": "item", "text": content}
        attach(container, node)
        lstack.append(node)

    if pending:
        todos.extend(pending)
    finalize(roots)
    return roots, todos, warnings


def finalize(nodes):
    """Section numbers (n only where not prev+1), drop private keys / empty lists."""
    last = {}
    for n in nodes:
        if n["type"] == "section":
            d = n.get("depth", n["_nat"])
            if "_n" in n and n["_n"] != last.get(d, 0) + 1:
                n["n"] = n["_n"]
            last[d] = n.get("_n", last.get(d, 0) + 1)
        for k in [k for k in n if k.startswith("_")]:
            del n[k]
        if n["type"] == "list":
            for it in n["items"]:
                it.pop("type", None)
                it.pop("_line", None)
                if it.get("children"):
                    finalize(it["children"])
                else:
                    it.pop("children", None)
        if n.get("children"):
            finalize(n["children"])
        elif "children" in n:
            del n["children"]
    return nodes


KEY_ORDER = ["type", "title", "summary", "depth", "n", "label", "kind", "role", "ordered",
             "start", "text", "header", "rows", "items", "children"]


def ordered_json(x):
    if isinstance(x, list):
        return [ordered_json(v) for v in x]
    if isinstance(x, dict):
        keys = sorted(x, key=lambda k: KEY_ORDER.index(k) if k in KEY_ORDER else 99)
        return {k: ordered_json(x[k]) for k in keys}
    return x


def build_doc(pid, md):
    nodes, todos, warnings = parse_md(md, pid)
    return {"part": int(pid), "nodes": ordered_json(nodes)}, todos, warnings


# ===========================================================================
# render-a: JSON -> Phase A text
# ===========================================================================
def render_a(nodes):
    out = []

    def section_marker(depth, num):
        if depth == 0:
            return "%d." % num
        if depth == 1:
            return "(%d)" % num
        if depth == 2:
            return "%d)" % num
        if depth == 3:
            return cm.lower_alpha(num) + ")"
        raise ValueError("section depth %d has no Phase A marker" % depth)

    def walk(children, level, parent_depth):
        last = {}
        for n in children:
            t = n["type"]
            pad = " " * level
            if t == "section":
                d = n.get("depth", parent_depth + 1)
                num = n.get("n", last.get(d, 0) + 1)
                last[d] = num
                text = n["title"] + (" - " + n["summary"] if "summary" in n else "")
                out.append(pad + section_marker(d, num) + " " + text)
                walk(n.get("children", []), level + 1, d)
                continue
            if t == "list":
                num = n.get("start", 1) - 1
                for it in n["items"]:
                    num = it.get("n", num + 1)
                    out.append(pad + cm.lower_alpha(num) + ") " + it["text"])
                    walk(it.get("children", []), level + 1, parent_depth)
                continue
            if t == "term":
                text = n["label"] + (" : " + n["text"] if "text" in n else "")
                out.append(pad + "◎ " + text)
            elif t == "item":
                role = n.get("role")
                if role == "then":
                    out.append(pad + "⇒ " + n["text"])
                elif role == "raw":
                    out.append(pad + " " + n["text"])
                else:
                    out.append(pad + "- " + n["text"])
            elif t == "note":
                k = n["kind"]
                lit = "(※ 암기법 : %s)" % n["text"] if k == "mnemonic" else "* " + n["text"]
                out.append(pad + " " + lit)
            elif t == "table":
                raise ValueError("table has no Phase A text yet")
            else:
                raise ValueError("unknown node type %r" % t)
            walk(n.get("children", []), level + 1, parent_depth)

    walk(nodes, 0, 0)
    return "\n".join(out)


# ===========================================================================
# commands
# ===========================================================================
def ids_arg(arg):
    return cm.all_ids() if arg == "all" else [arg]


def read_src(pid):
    with open(src_path(pid), encoding="utf-8") as f:
        return f.read()


def cmd_migrate(arg):
    total = Counter()
    for pid in ids_arg(arg):
        md, counts = migrate(pid)
        os.makedirs(SRC_DIR, exist_ok=True)
        with open(src_path(pid), "w", encoding="utf-8") as f:
            f.write(md)
        total += counts
        print("wrote %s  (%d TODOs%s)" % (os.path.relpath(src_path(pid), ROOT), sum(counts.values()),
                                           ": " + ", ".join("%s %d" % kv for kv in sorted(counts.items()))
                                           if counts else ""))
    return 0


def cmd_build(arg, strict):
    rc = 0
    for pid in ids_arg(arg):
        if arg == "all" and not os.path.exists(src_path(pid)):
            continue
        try:
            doc, todos, warnings = build_doc(pid, read_src(pid))
        except BuildError as e:
            print("ERROR %s" % e)
            rc = 1
            continue
        status = "OK"
        if todos:
            status = "FAIL (--strict, not written)" if strict else "WARN"
            if strict:
                rc = 1
        if not (strict and todos):
            os.makedirs(BUILD_DIR, exist_ok=True)
            with open(build_path(pid), "w", encoding="utf-8") as f:
                json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
                f.write("\n")
        c = Counter(t[1] for t in todos)
        print("%s %s -> %s  (%d TODOs%s)" % (
            status, pid, os.path.relpath(build_path(pid), ROOT), len(todos),
            ": " + ", ".join("%s %d" % kv for kv in sorted(c.items())) if c else ""))
        if strict:
            for lineno, smell, reason in todos[:20]:
                print("  line %d TODO(%s): %s" % (lineno, smell, reason))
    return rc


def load_json(pid):
    if os.path.exists(build_path(pid)):
        with open(build_path(pid), encoding="utf-8") as f:
            return json.load(f)
    return build_doc(pid, read_src(pid))[0]


def parity_one(pid, fresh):
    try:
        expected = cm.to_string(cm.recognize(cm.read_txt(pid)))
    except RecognizerCrash as e:
        return False, "txt crashes the app parser: %s" % e, ""
    src = "md"
    if fresh or not os.path.exists(src_path(pid)):
        md, _ = migrate(pid)
        src = "in-memory migrate"
    else:
        md = read_src(pid)
    try:
        doc = build_doc(pid, md)[0]
        got = render_a(doc["nodes"])
    except (BuildError, ValueError, RecognizerCrash) as e:
        return False, "build/render failed: %s" % e, src
    if got.encode() == expected.encode():
        return True, "%d lines, %d bytes identical" % (expected.count("\n") + 1, len(expected.encode())), src
    a, b = expected.split("\n"), got.split("\n")
    i = next((k for k in range(min(len(a), len(b))) if a[k] != b[k]), min(len(a), len(b)))
    ea = a[i] if i < len(a) else "<EOF>"
    gb = b[i] if i < len(b) else "<EOF>"
    return False, "first difference at rendered line %d: expected %r got %r" % (
        i + 1, cm.snippet(ea), cm.snippet(gb)), src


def cmd_parity(arg, fresh):
    ok = 0
    ids = ids_arg(arg)
    for pid in ids:
        good, msg, src = parity_one(pid, fresh)
        ok += good
        print("%s %s  %s  [%s]" % ("OK  " if good else "DIFF", pid, msg, src))
    if len(ids) > 1:
        print("parity: %d / %d parts OK" % (ok, len(ids)))
    return 0 if ok == len(ids) else 1


def cmd_todos(arg):
    for pid in ids_arg(arg):
        if not os.path.exists(src_path(pid)):
            continue
        c = Counter(m.group(1) or "" for m in re.finditer(r"<!-- TODO(?:\(([^)]*)\))?", read_src(pid)))
        print("%s  %d  %s" % (pid, sum(c.values()), ", ".join("%s %d" % kv for kv in sorted(c.items()))))
    return 0


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    cmd, arg = argv[1], argv[2]
    try:
        if cmd == "migrate":
            return cmd_migrate(arg)
        if cmd == "build":
            return cmd_build(arg, "--strict" in argv)
        if cmd == "render-a":
            sys.stdout.write(render_a(load_json(arg)["nodes"]) + "\n")
            return 0
        if cmd == "parity":
            return cmd_parity(arg, "--fresh" in argv)
        if cmd == "todos":
            return cmd_todos(arg)
    except RecognizerCrash as e:
        print("CRASH (Swift would trap): %s" % e)
        return 1
    except BuildError as e:
        print("ERROR %s" % e)
        return 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
