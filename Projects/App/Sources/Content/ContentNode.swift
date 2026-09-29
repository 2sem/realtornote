//
//  ContentNode.swift
//  App
//
//  Content tree migration (docs/plans/content-tree.md, P2).
//
//  Codable model for `ContentSource/build/parts/<id>.json`, produced by
//  `Scripts/content_tree.py build`. Schema: `{"part": <id>, "nodes": [node...]}`.
//  Decoding is lenient — unknown/future fields on a node are simply ignored,
//  matching `content_tree.py`'s `finalize()` output (only fields that differ
//  from the natural/derived value are emitted).
//

import Foundation

/// Top-level shape of a `parts/<id>.json` content-tree document.
struct ContentDocument: Decodable {
    let part: Int
    let nodes: [ContentNode]
}

/// One node of the content tree. See `docs/plans/content-tree.md` §1/§3 and
/// `Scripts/content_tree.py`'s module docstring for the exact JSON shape and
/// the Phase A -> display-symbol mapping (implemented by `ContentTreeRenderer`).
indirect enum ContentNode: Decodable {
    case section(SectionNode)
    case term(TermNode)
    case list(ListNode)
    case item(ItemNode)
    case note(NoteNode)
    case table(TableNode)
    /// Forward-compatible fallback for a node type this build doesn't know about yet.
    case unknown

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        switch type {
        case "section":
            self = .section(try SectionNode(from: decoder))
        case "term":
            self = .term(try TermNode(from: decoder))
        case "list":
            self = .list(try ListNode(from: decoder))
        case "item":
            self = .item(try ItemNode(from: decoder))
        case "note":
            self = .note(try NoteNode(from: decoder))
        case "table":
            self = .table(try TableNode(from: decoder))
        default:
            self = .unknown
        }
    }

    /// `section {title, summary?, depth?, n?, children?}` — depth/`n` are only present
    /// when they differ from the natural nesting position / sibling sequence.
    struct SectionNode: Decodable {
        let title: String
        let summary: String?
        let depth: Int?
        let n: Int?
        let children: [ContentNode]?
    }

    /// `term {label, text?, children?}` — Phase A: `◎ label` or `◎ label : text`.
    struct TermNode: Decodable {
        let label: String
        let text: String?
        let children: [ContentNode]?
    }

    /// `list {ordered: true, start?, items: [{text, n?, children?}]}` — Phase A: `a) b) c) ...`.
    struct ListNode: Decodable {
        let ordered: Bool?
        let start: Int?
        let items: [ListItem]

        struct ListItem: Decodable {
            let text: String
            let n: Int?
            let children: [ContentNode]?
        }
    }

    /// `item {text, role?, children?}` — role `"then"` -> `⇒`, `"raw"` -> literal text
    /// (no marker), no role -> `-`.
    struct ItemNode: Decodable {
        let text: String
        let role: String?
        let children: [ContentNode]?
    }

    /// `note {kind, text}` — kind `"mnemonic"` -> `(※ 암기법 : text)`, `"tip"`/`"formula"` -> `* text`.
    struct NoteNode: Decodable {
        let kind: String
        let text: String
    }

    /// `table {header, rows}` — no Phase A text exists yet (no part currently has one);
    /// `ContentTreeRenderer` falls back to a plain line-per-row rendering.
    struct TableNode: Decodable {
        let header: [String]
        let rows: [[String]]
    }
}

extension String {
    /// True when this stored `Part.content` is a content-tree JSON document rather than
    /// the legacy marker-line `.txt` format. Detected by content (first non-whitespace
    /// character is `{`), not by which loader produced it, since `Part.content` is just a
    /// raw string copied byte-for-byte regardless of source — see `ContentLoader`.
    var isContentTreeJSON: Bool {
        guard let firstNonWhitespace = first(where: { !$0.isWhitespace }) else { return false }
        return firstNonWhitespace == "{"
    }
}
