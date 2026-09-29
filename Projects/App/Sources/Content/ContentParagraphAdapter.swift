//
//  ContentParagraphAdapter.swift
//  App
//
//  Content tree migration (docs/plans/content-tree.md, P3 prerequisite).
//
//  Direct `[ContentNode] -> [LSDocumentRecognizer.LSDocumentParagraph]` adapter used by
//  `ContentRendering.paragraphs(for:)` for JSON parts. It builds the paragraph graph
//  straight from the JSON tree's own parent/child structure — it never renders to Phase A
//  text and re-runs `LSDocumentRecognizer.recognize` (the old render-then-reparse path).
//
//  Why this matters: `recognize(doc:)` rebuilds nesting from a flat line sequence using a
//  heuristic (see its `before`/`findParent`/`indexingParent` dance). That heuristic is
//  exactly what produced the *wrong* trees the content-tree migration exists to fix (docs/
//  plans/content-tree.md §7 — e.g. a `◎` term getting hoisted above the section it actually
//  belongs to). Once P3 starts moving nodes in the JSON to fix such cases, re-parsing the
//  rendered text would silently rebuild the old wrong shape and the Quiz would disagree
//  with what PartScreen displays. This adapter instead trusts the JSON's own nesting.
//
//  Faithfulness to the legacy shape (for parts that still mirror the old parse — the P2/P3
//  invariant `ContentTreeTests` proves): each node type maps to the same (indexType, text)
//  the old parser would have recognized for the line `ContentTreeRenderer` renders for it,
//  and structure mirrors the JSON tree exactly, with `list` nodes transparent (their items
//  attach directly to the list's own parent paragraph, matching how `ContentTreeRenderer`
//  renders list items at the *list's* level, not as children of a "list" line — there is no
//  "list" line).
//
//  Hidden index quirk: `LSDocumentRecognizer.recognize` always overrides a paragraph's
//  parsed index with `before.index + 1` whenever the immediately preceding *emitted* line
//  (in flattened, pre-order/rendered sequence — not necessarily a sibling by nesting) has
//  the same `indexType` — see the `before.indexType == paragraph.indexType` branch. This
//  fires even for `dash`/`term`/`next`/`none` lines, which otherwise always parse to index
//  0, and even for numbered lines where it can clobber an explicit `n`/`start` gap. Nothing
//  in the app reads `.index` for JSON parts (`RNQuestionInfo`/`QuizScreenModel` only use
//  `.text`/`.children`/`.parent`/`.isRoot`/`.allParagraphs`), but `ContentTreeTests` proves
//  full (level, indexType, index, text) equivalence against `recognize(render(tree))`, so
//  this adapter reproduces the override exactly via a single threaded `before` reference.
//
//  Do not "fix" or simplify this against `ContentTreeRenderer.walk` without re-running the
//  equivalence tests — the two must stay in lockstep (same emission order, same per-call
//  `lastNumberByDepth` reset) since the override quirk depends on emission order.
//

import Foundation
import LSExtensions

enum ContentParagraphAdapter {
    typealias Paragraph = LSDocumentRecognizer.LSDocumentParagraph
    typealias IndexType = Paragraph.IndexType

    /// Converts a content-tree document's nodes directly into paragraph objects, preserving
    /// the JSON's own nesting. Returns the root paragraphs (mirrors what
    /// `LSDocumentRecognizer.recognize` returns: the top-level paragraphs with no parent).
    static func paragraphs(for nodes: [ContentNode]) -> [Paragraph] {
        var roots: [Paragraph] = []
        var before: Paragraph?
        walk(nodes, parent: nil, parentDepth: 0, roots: &roots, before: &before)
        return roots
    }

    /// Mirrors `ContentTreeRenderer.sectionMarker`'s depth -> indexType mapping. Depth > 3
    /// has no dedicated Phase A marker (renderer falls back to a bare `"N)"` line), which
    /// parses back as `.half_bracket_number`, so that's the fallback here too.
    private static func effectiveSectionIndexType(depth: Int) -> IndexType {
        switch depth {
        case 0: return .number
        case 1: return .brackets_number
        case 2: return .half_bracket_number
        case 3: return .half_bracket_alpha
        default: return .half_bracket_number
        }
    }

    /// Walks one sibling list exactly like `ContentTreeRenderer.walk` — same node order,
    /// same per-call `lastNumberByDepth` reset — but attaches paragraph objects to `parent`
    /// instead of appending rendered text lines.
    private static func walk(
        _ children: [ContentNode],
        parent: Paragraph?,
        parentDepth: Int,
        roots: inout [Paragraph],
        before: inout Paragraph?
    ) {
        var lastNumberByDepth: [Int: Int] = [:]

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
                let paragraph = emit(
                    indexType: effectiveSectionIndexType(depth: depth),
                    naturalIndex: num,
                    text: text,
                    parent: parent,
                    roots: &roots,
                    before: &before
                )
                walk(section.children ?? [], parent: paragraph, parentDepth: depth, roots: &roots, before: &before)

            case .list(let list):
                // Transparent: items attach to `parent` directly, not to a "list" paragraph
                // (there is no rendered "list" line — see `ContentTreeRenderer.walk`).
                var num = (list.start ?? 1) - 1
                for item in list.items {
                    num = item.n ?? (num + 1)
                    let paragraph = emit(
                        indexType: .half_bracket_alpha,
                        naturalIndex: num,
                        text: item.text,
                        parent: parent,
                        roots: &roots,
                        before: &before
                    )
                    walk(item.children ?? [], parent: paragraph, parentDepth: parentDepth, roots: &roots, before: &before)
                }

            case .term(let term):
                var text = term.label
                if let termText = term.text {
                    text += " : " + termText
                }
                let paragraph = emit(
                    indexType: .term,
                    naturalIndex: 0,
                    text: text,
                    parent: parent,
                    roots: &roots,
                    before: &before
                )
                walk(term.children ?? [], parent: paragraph, parentDepth: parentDepth, roots: &roots, before: &before)

            case .item(let item):
                let indexType: IndexType
                switch item.role {
                case "then": indexType = .next
                case "raw": indexType = .none
                default: indexType = .dash
                }
                let paragraph = emit(
                    indexType: indexType,
                    naturalIndex: 0,
                    text: item.text,
                    parent: parent,
                    roots: &roots,
                    before: &before
                )
                walk(item.children ?? [], parent: paragraph, parentDepth: parentDepth, roots: &roots, before: &before)

            case .note(let note):
                // No Phase A marker of its own — the whole rendered line (parens/asterisk
                // included) is what `recognize` would treat as this paragraph's `.text`
                // (matches `IndexType.none`'s catch-all: no marker to strip). No children
                // in the schema, matching `NoteNode` and `ContentTreeRenderer`.
                let literal = note.kind == "mnemonic"
                    ? "(※ 암기법 : \(note.text))"
                    : "* " + note.text
                emit(indexType: .none, naturalIndex: 0, text: literal, parent: parent, roots: &roots, before: &before)

            case .table:
                emitTableLines(node, parent: parent, roots: &roots, before: &before)

            case .unknown:
                continue
            }
        }
    }

    /// Creates one paragraph, attaches it to `parent` (or `roots` when `parent == nil`),
    /// and applies `LSDocumentRecognizer.recognize`'s "same indexType as the immediately
    /// preceding emitted line" index override — see the file-level doc comment.
    @discardableResult
    private static func emit(
        indexType: IndexType,
        naturalIndex: Int,
        text: String,
        parent: Paragraph?,
        roots: inout [Paragraph],
        before: inout Paragraph?
    ) -> Paragraph {
        let paragraph = Paragraph("")
        paragraph.text = text
        paragraph.indexType = indexType
        if let before, before.indexType == indexType {
            paragraph.index = before.index + 1
        } else {
            paragraph.index = naturalIndex
        }
        paragraph.parent = parent
        if let parent {
            parent.children.append(paragraph)
        } else {
            roots.append(paragraph)
        }
        before = paragraph
        return paragraph
    }

    /// No part currently has a `table` node (docs/plans/content-tree.md marks tables as a
    /// later addition) and `ContentTreeRenderer` has no real Phase A text for one either —
    /// it falls back to plain pipe-joined lines. Mirror that here so a future table doesn't
    /// crash the quiz pipeline or silently drop content; each line becomes an untyped
    /// (`.none`) paragraph the same way an unmarked legacy line would.
    private static func emitTableLines(
        _ node: ContentNode,
        parent: Paragraph?,
        roots: inout [Paragraph],
        before: inout Paragraph?
    ) {
        guard case .table(let table) = node else { return }
        if !table.header.isEmpty {
            emit(indexType: .none, naturalIndex: 0, text: table.header.joined(separator: " | "), parent: parent, roots: &roots, before: &before)
        }
        for row in table.rows {
            emit(indexType: .none, naturalIndex: 0, text: row.joined(separator: " | "), parent: parent, roots: &roots, before: &before)
        }
    }
}
