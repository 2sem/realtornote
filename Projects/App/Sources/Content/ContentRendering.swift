//
//  ContentRendering.swift
//  App
//
//  Content tree migration (docs/plans/content-tree.md, P2).
//
//  Single place that picks the content-tree JSON path vs. the legacy `.txt` /
//  `LSDocumentRecognizer` path for a `Part.content` string, used by both the display
//  pipeline (`PartScreenModel`) and the quiz pipeline (`QuizScreenModel`). Parts are
//  migrated one at a time (docs/plans/content-tree.md P3), so both formats coexist and
//  each `Part.content` is checked independently via `String.isContentTreeJSON`.
//

import Foundation

enum ContentRendering {
    /// The text shown in `PartScreen` (feeds `SwiftUITextView`, search highlighting, and
    /// scroll-position math) — unchanged for legacy `.txt` parts, and Phase A rendered
    /// text (byte-identical to what the legacy pipeline would have produced) for
    /// already-migrated JSON parts.
    static func displayText(for content: String) -> String {
        if let document = decodeContentTree(content) {
            return ContentTreeRenderer.render(document.nodes)
        }
        let paragraphs = LSDocumentRecognizer.shared.recognize(doc: content)
        return LSDocumentRecognizer.shared.toString(paragraphs)
    }

    /// The paragraph tree `RNQuestionInfo.createQuestions` consumes. For a JSON part this
    /// builds paragraphs directly from the tree via `ContentParagraphAdapter`, preserving
    /// the JSON's own nesting exactly — it does NOT render to Phase A text and re-run the
    /// legacy `LSDocumentRecognizer.recognize` heuristic. That render-then-reparse used to
    /// be the whole implementation, but it would silently rebuild the *old, heuristic* tree
    /// shape once P3 starts fixing structure in the JSON (docs/plans/content-tree.md P3 /
    /// §7), making the Quiz disagree with what PartScreen displays. See
    /// `ContentParagraphAdapter`'s file-level doc comment for the equivalence argument.
    static func paragraphs(for content: String) -> [LSDocumentRecognizer.LSDocumentParagraph] {
        if let document = decodeContentTree(content) {
            return ContentParagraphAdapter.paragraphs(for: document.nodes)
        }
        return LSDocumentRecognizer.shared.recognize(doc: content)
    }

    /// Decodes `content` as a content-tree JSON document when it looks like one.
    /// Returns nil (never throws) for legacy `.txt` content or a JSON decode failure, so
    /// callers can fall back to the legacy pipeline defensively.
    private static func decodeContentTree(_ content: String) -> ContentDocument? {
        guard content.isContentTreeJSON, let data = content.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(ContentDocument.self, from: data)
        } catch {
            print("[ContentRendering] Failed to decode content-tree JSON, falling back to legacy renderer: \(error)")
            return nil
        }
    }
}
