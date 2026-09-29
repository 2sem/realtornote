//
//  ContentTreeRenderer.swift
//  App
//
//  Content tree migration (docs/plans/content-tree.md, P2).
//
//  Phase A renderer: `ContentNode` tree -> exactly the text
//  `LSDocumentRecognizer.toString(LSDocumentRecognizer.recognize(doc:))` produces for the
//  equivalent legacy `.txt` marker text. This is a 1:1 Swift port of `render_a` in
//  `Scripts/content_tree.py` (see its docstring / the "MIGRATE MAPPING" section for the
//  reasoning); `Scripts/content_tree.py parity` proves the two renderers agree for every
//  already-migrated part. Phase B (post-exam symbol set) is out of scope here.
//
//  Do not "fix" or simplify this against the Python reference without re-running parity —
//  every branch here (including the depth->marker table and the per-list-node/per-depth
//  numbering resets) mirrors a specific line in `render_a`.
//

import Foundation
import LSExtensions

enum ContentTreeRenderer {
    /// Renders a full content-tree document's nodes to Phase A display text.
    static func render(_ nodes: [ContentNode]) -> String {
        var out: [String] = []
        walk(nodes, level: 0, parentDepth: 0, into: &out)
        return out.joined(separator: "\n")
    }

    /// Phase A marker for a section at `depth` (0-based, root's children = depth 0).
    /// Matches `render_a`'s `section_marker`; depth > 3 has no Phase A marker in the
    /// current content (no migrated part nests that deep) and falls back to `N)`.
    private static func sectionMarker(depth: Int, num: Int) -> String {
        switch depth {
        case 0: return "\(num)."
        case 1: return "(\(num))"
        case 2: return "\(num))"
        case 3: return num.lowerAlpha + ")"
        default: return "\(num))"
        }
    }

    /// Walks one sibling list. `last` (section number per depth) is local to this call,
    /// exactly like the Python `last = {}` inside `walk()` — each nested sibling group
    /// gets its own counters.
    private static func walk(_ children: [ContentNode], level: Int, parentDepth: Int, into out: inout [String]) {
        var lastNumberByDepth: [Int: Int] = [:]
        let pad = String(repeating: " ", count: level)

        for node in children {
            switch node {
            case .section(let section):
                let depth = section.depth ?? (parentDepth + 1)
                let num = section.n ?? ((lastNumberByDepth[depth] ?? 0) + 1)
                lastNumberByDepth[depth] = num
                var text = section.title
                if let summary = section.summary {
                    text += " - " + summary
                }
                out.append(pad + sectionMarker(depth: depth, num: num) + " " + text)
                walk(section.children ?? [], level: level + 1, parentDepth: depth, into: &out)

            case .list(let list):
                // Ordered list: its own local counter, independent of `lastNumberByDepth`.
                var num = (list.start ?? 1) - 1
                for item in list.items {
                    num = item.n ?? (num + 1)
                    out.append(pad + num.lowerAlpha + ") " + item.text)
                    walk(item.children ?? [], level: level + 1, parentDepth: parentDepth, into: &out)
                }

            case .term(let term):
                var text = term.label
                if let termText = term.text {
                    text += " : " + termText
                }
                out.append(pad + "◎ " + text)
                walk(term.children ?? [], level: level + 1, parentDepth: parentDepth, into: &out)

            case .item(let item):
                switch item.role {
                case "then":
                    out.append(pad + "⇒ " + item.text)
                case "raw":
                    // Untyped legacy line: no marker at all, single leading space (matches
                    // `IndexType.none.toIndexString` == "" -> `pad + "" + " " + text`).
                    out.append(pad + " " + item.text)
                default:
                    out.append(pad + "- " + item.text)
                }
                walk(item.children ?? [], level: level + 1, parentDepth: parentDepth, into: &out)

            case .note(let note):
                let literal = note.kind == "mnemonic"
                    ? "(※ 암기법 : \(note.text))"
                    : "* " + note.text
                out.append(pad + " " + literal)
                // Notes have no children in the schema.

            case .table:
                // `render_a` has no Phase A text for tables (none exist yet - the plan
                // calls tables a later addition). Render something safe instead of
                // crashing: header + rows as plain lines.
                renderTableAsLines(node, pad: pad, into: &out)

            case .unknown:
                continue
            }
        }
    }

    private static func renderTableAsLines(_ node: ContentNode, pad: String, into out: inout [String]) {
        guard case .table(let table) = node else { return }
        if !table.header.isEmpty {
            out.append(pad + table.header.joined(separator: " | "))
        }
        for row in table.rows {
            out.append(pad + row.joined(separator: " | "))
        }
    }
}
