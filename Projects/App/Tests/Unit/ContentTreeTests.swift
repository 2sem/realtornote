//
//  ContentTreeTests.swift
//  AppTests
//
//  Content tree migration (docs/plans/content-tree.md, P2). Unit tests for the JSON model,
//  the Phase A renderer, and the legacy-vs-JSON pipeline equivalence.
//
//  IMPORTANT: study content is private (public repo). Every fixture below is synthetic
//  placeholder text hand-written for this test, never real exam content. Fixtures were
//  cross-checked against `Scripts/content_tree.py`'s `render_a` (see the equivalent
//  python snippet in the P2 implementation notes) but no content file is read here.
//

import XCTest
@testable import App

final class ContentTreeTests: XCTestCase {

    // MARK: - Decoding

    func testDecode_allNodeTypes() throws {
        let json = """
        {"part": 1, "nodes": [
            {"type": "section", "title": "T", "summary": "S", "depth": 2, "n": 5, "children": []},
            {"type": "term", "label": "L", "text": "TX"},
            {"type": "term", "label": "L2"},
            {"type": "list", "ordered": true, "start": 3, "items": [{"text": "a"}, {"text": "b", "n": 7}]},
            {"type": "item", "text": "I", "role": "then"},
            {"type": "item", "text": "I2"},
            {"type": "note", "kind": "mnemonic", "text": "N"},
            {"type": "table", "header": ["h1", "h2"], "rows": [["r1a", "r1b"]]},
            {"type": "something_future", "whatever": 1}
        ]}
        """
        let doc = try JSONDecoder().decode(ContentDocument.self, from: Data(json.utf8))
        XCTAssertEqual(doc.part, 1)
        XCTAssertEqual(doc.nodes.count, 9)

        guard case .section(let section) = doc.nodes[0] else { return XCTFail("expected section") }
        XCTAssertEqual(section.title, "T")
        XCTAssertEqual(section.summary, "S")
        XCTAssertEqual(section.depth, 2)
        XCTAssertEqual(section.n, 5)

        guard case .term(let term1) = doc.nodes[1] else { return XCTFail("expected term") }
        XCTAssertEqual(term1.label, "L")
        XCTAssertEqual(term1.text, "TX")

        guard case .term(let term2) = doc.nodes[2] else { return XCTFail("expected term") }
        XCTAssertNil(term2.text)

        guard case .list(let list) = doc.nodes[3] else { return XCTFail("expected list") }
        XCTAssertEqual(list.start, 3)
        XCTAssertEqual(list.items.map(\.text), ["a", "b"])
        XCTAssertEqual(list.items[1].n, 7)

        guard case .item(let item1) = doc.nodes[4] else { return XCTFail("expected item") }
        XCTAssertEqual(item1.role, "then")

        guard case .item(let item2) = doc.nodes[5] else { return XCTFail("expected item") }
        XCTAssertNil(item2.role)

        guard case .note(let note) = doc.nodes[6] else { return XCTFail("expected note") }
        XCTAssertEqual(note.kind, "mnemonic")
        XCTAssertEqual(note.text, "N")

        guard case .table(let table) = doc.nodes[7] else { return XCTFail("expected table") }
        XCTAssertEqual(table.header, ["h1", "h2"])
        XCTAssertEqual(table.rows, [["r1a", "r1b"]])

        guard case .unknown = doc.nodes[8] else { return XCTFail("expected unknown fallback") }
    }

    func testIsContentTreeJSON() {
        XCTAssertTrue("{\"part\":1,\"nodes\":[]}".isContentTreeJSON)
        XCTAssertTrue("  \n  {\"part\":1}".isContentTreeJSON)
        XCTAssertFalse("(1) legacy text".isContentTreeJSON)
        XCTAssertFalse("".isContentTreeJSON)
    }

    // MARK: - Phase A renderer: every node type + every override, in one synthetic tree

    /// Hand-built to exercise: section depth via natural nesting, explicit `depth` override,
    /// explicit `n` override; term with and without `text`; item with no role / `then` / `raw`;
    /// note `mnemonic` / `tip` / `formula`; ordered list with `start` override and a per-item
    /// `n` override. Expected text was cross-checked against `Scripts/content_tree.py`'s
    /// `render_a(nodes)` for this exact tree (byte-identical output confirmed while
    /// implementing `ContentTreeRenderer`).
    func testRender_syntheticTreeCoversAllNodeTypesAndOverrides() throws {
        let json = """
        {"part": 9999, "nodes": [
            {"type": "section", "title": "챕터루트", "children": [
                {"type": "section", "title": "섹션하나", "n": 3, "children": [
                    {"type": "section", "title": "서브섹션", "depth": 3, "children": [
                        {"type": "term", "label": "라벨1", "children": [
                            {"type": "item", "text": "일반항목"}
                        ]},
                        {"type": "term", "label": "라벨2", "text": "텍스트2"},
                        {"type": "item", "text": "다음항목", "role": "then"},
                        {"type": "item", "text": "원문항목", "role": "raw"},
                        {"type": "note", "kind": "mnemonic", "text": "암기내용"},
                        {"type": "note", "kind": "tip", "text": "참고내용"},
                        {"type": "note", "kind": "formula", "text": "공식내용"},
                        {"type": "list", "ordered": true, "start": 3, "items": [
                            {"text": "목록셋"},
                            {"text": "목록다섯", "n": 5},
                            {"text": "목록여섯"}
                        ]}
                    ]}
                ]}
            ]}
        ]}
        """
        let expected = """
        (1) 챕터루트
         3) 섹션하나
          a) 서브섹션
           ◎ 라벨1
            - 일반항목
           ◎ 라벨2 : 텍스트2
           ⇒ 다음항목
            원문항목
            (※ 암기법 : 암기내용)
            * 참고내용
            * 공식내용
           c) 목록셋
           e) 목록다섯
           f) 목록여섯
        """

        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(json.utf8))
        XCTAssertEqual(ContentTreeRenderer.render(document.nodes), expected)
    }

    func testRender_table_fallsBackToPlainLinesInsteadOfCrashing() throws {
        // `render_a` (Python reference) has no Phase A mapping for tables at all — no part
        // currently has one. `ContentTreeRenderer` renders something safe instead: header +
        // rows as plain pipe-joined lines. This is our own addition, not a legacy behavior
        // to match, so it's only tested against itself.
        let json = """
        {"part": 1, "nodes": [
            {"type": "table", "header": ["지역", "보증금"], "rows": [["서울", "1000"], ["기타", "500"]]}
        ]}
        """
        let expected = "지역 | 보증금\n서울 | 1000\n기타 | 500"
        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(json.utf8))
        XCTAssertEqual(ContentTreeRenderer.render(document.nodes), expected)
    }

    // MARK: - Legacy `.txt` pipeline vs. content-tree JSON pipeline equivalence

    /// A synthetic legacy marker-line part and the content-tree JSON that
    /// `Scripts/content_tree.py migrate` + `build` produce for it (verified locally against
    /// the real tool while implementing this: `parity 9999` reported "OK ... identical").
    /// Proves `ContentTreeRenderer.render` reproduces exactly what
    /// `LSDocumentRecognizer.toString(LSDocumentRecognizer.recognize(doc:))` produces for the
    /// equivalent legacy text, including the recognizer's nesting heuristic (e.g. an
    /// untyped/differently-marked line becomes a *child* of the previous line, not a sibling).
    func testRender_matchesLegacyRecognizerOutput_forEquivalentStructure() throws {
        let legacyText = """
        (1) 대분류
        1) 중분류
        ◎ 정의 : 이것은 설명이다
        - 항목가
        ⇒ 항목나
        a) 목록하나
        b) 목록둘
        (※ 암기법 : 두문자니모닉)
        * 참고사항입니다
        """

        let json = """
        {"part": 9999, "nodes": [
            {"type": "section", "title": "대분류", "children": [
                {"type": "section", "title": "중분류", "children": [
                    {"type": "term", "label": "정의", "text": "이것은 설명이다", "children": [
                        {"type": "item", "text": "항목가", "children": [
                            {"type": "item", "role": "then", "text": "항목나", "children": [
                                {"type": "list", "ordered": true, "items": [
                                    {"text": "목록하나"},
                                    {"text": "목록둘", "children": [
                                        {"type": "note", "kind": "mnemonic", "text": "두문자니모닉"},
                                        {"type": "note", "kind": "tip", "text": "참고사항입니다"}
                                    ]}
                                ]}
                            ]}
                        ]}
                    ]}
                ]}
            ]}
        ]}
        """

        let legacyParagraphs = LSDocumentRecognizer.shared.recognize(doc: legacyText)
        let legacyRendered = LSDocumentRecognizer.shared.toString(legacyParagraphs)

        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(json.utf8))
        let treeRendered = ContentTreeRenderer.render(document.nodes)

        XCTAssertEqual(treeRendered, legacyRendered)

        // Also exercise the ContentRendering facade both screens go through, for both
        // the legacy string and the JSON string (round-tripped through Data like the
        // real `Part.content` would be).
        XCTAssertEqual(ContentRendering.displayText(for: legacyText), legacyRendered)
        XCTAssertEqual(ContentRendering.displayText(for: json), treeRendered)
    }

    func testParagraphsAdapter_jsonAndLegacyProduceEquivalentTreeShape() throws {
        // ContentRendering.paragraphs(for:) must, for a JSON part, hand back exactly what
        // the legacy recognizer would build for the Phase A rendered text — same
        // parent/children/level/text — since it runs the JSON path's rendered text back
        // through the same LSDocumentRecognizer.recognize the legacy path uses directly.
        let legacyText = """
        (1) 대분류
        1) 중분류
        ◎ 정의 : 이것은 설명이다
        - 항목가
        """
        let json = """
        {"part": 9999, "nodes": [
            {"type": "section", "title": "대분류", "children": [
                {"type": "section", "title": "중분류", "children": [
                    {"type": "term", "label": "정의", "text": "이것은 설명이다", "children": [
                        {"type": "item", "text": "항목가"}
                    ]}
                ]}
            ]}
        ]}
        """

        let fromLegacy = ContentRendering.paragraphs(for: legacyText)
        let fromJSON = ContentRendering.paragraphs(for: json)

        func flatten(_ paragraphs: [LSDocumentRecognizer.LSDocumentParagraph]) -> [(Int, String)] {
            paragraphs.flatMap { [( $0.level, $0.text )] + flatten($0.children) }
        }

        XCTAssertEqual(flatten(fromLegacy).map(\.0), flatten(fromJSON).map(\.0))
        XCTAssertEqual(flatten(fromLegacy).map(\.1), flatten(fromJSON).map(\.1))
    }

    // MARK: - ContentParagraphAdapter: full (level, indexType, index, text) equivalence

    /// Flattens a paragraph forest in pre-order, capturing every field `ContentTreeTests`
    /// (and, potentially, a future consumer) could rely on: level, indexType, index, text.
    private func flattenFull(
        _ paragraphs: [LSDocumentRecognizer.LSDocumentParagraph]
    ) -> [(level: Int, indexType: LSDocumentRecognizer.LSDocumentParagraph.IndexType, index: Int, text: String)] {
        paragraphs.flatMap { paragraph in
            [(paragraph.level, paragraph.indexType, paragraph.index, paragraph.text)] + flattenFull(paragraph.children)
        }
    }

    /// Decodes `json`, then asserts `ContentParagraphAdapter.paragraphs(for:)` matches
    /// `LSDocumentRecognizer.recognize(doc: ContentTreeRenderer.render(nodes))` field for
    /// field (level, indexType, index, text) in pre-order — the equivalence proof required
    /// by docs/plans/content-tree.md P3 prerequisite, for trees that mirror the old parse.
    private func assertParagraphAdapterMatchesRecognize(_ json: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(json.utf8))
        let rendered = ContentTreeRenderer.render(document.nodes)
        let reference = LSDocumentRecognizer.shared.recognize(doc: rendered)
        let adapted = ContentParagraphAdapter.paragraphs(for: document.nodes)

        let referenceFlat = flattenFull(reference)
        let adaptedFlat = flattenFull(adapted)

        XCTAssertEqual(adaptedFlat.count, referenceFlat.count, file: file, line: line)
        for (i, (ref, got)) in zip(referenceFlat, adaptedFlat).enumerated() {
            XCTAssertEqual(got.level, ref.level, "level mismatch at node \(i) (\(got.text.prefix(20)))", file: file, line: line)
            XCTAssertEqual(got.indexType, ref.indexType, "indexType mismatch at node \(i) (\(got.text.prefix(20)))", file: file, line: line)
            XCTAssertEqual(got.index, ref.index, "index mismatch at node \(i) (\(got.text.prefix(20)))", file: file, line: line)
            XCTAssertEqual(got.text, ref.text, "text mismatch at node \(i)", file: file, line: line)
        }
    }

    /// Section depth coverage: an explicit `depth: 0` root (`.number`, "1.") through natural
    /// depths 1/2/3 (`.brackets_number`/`.half_bracket_number`/`.half_bracket_alpha`) down to
    /// an explicit `depth: 4` override (falls back to `.half_bracket_number`, "1)"), each the
    /// sole child of its parent, ending in a plain dash item. A single unbroken chain (no
    /// sibling-of-different-type transitions) so the recognizer's `findParent`/`sibil`
    /// climbing can't reparent anything — every level here is provably a mirror of the old
    /// parse by construction (index 1 at every level keeps the `sibil` branch's `index == 1`
    /// case, which re-attaches to `before` exactly as the JSON already has it).
    func testParagraphAdapter_matchesRecognize_sectionDepthChain() throws {
        try assertParagraphAdapterMatchesRecognize("""
        {"part": 9999, "nodes": [
            {"type": "section", "title": "루트", "depth": 0, "children": [
                {"type": "section", "title": "레벨1", "children": [
                    {"type": "section", "title": "레벨2", "children": [
                        {"type": "section", "title": "레벨3", "children": [
                            {"type": "section", "title": "레벨4", "depth": 4, "children": [
                                {"type": "item", "text": "내용"}
                            ]}
                        ]}
                    ]}
                ]}
            ]}
        ]}
        """)
    }

    /// term -> dash item -> then item, with two `raw` items as siblings (both share `.none`
    /// indexType, so the second becomes a sibling of the first via the recognizer's "same
    /// indexType as immediately preceding line" branch — matching them being siblings in the
    /// JSON's own `children` array). Notes are covered separately: the quiz adapter skips them.
    func testParagraphAdapter_matchesRecognize_termItemsAndAllNoteKinds() throws {
        try assertParagraphAdapterMatchesRecognize("""
        {"part": 9999, "nodes": [
            {"type": "section", "title": "대분류", "children": [
                {"type": "term", "label": "정의", "text": "설명", "children": [
                    {"type": "item", "text": "항목가", "children": [
                        {"type": "item", "role": "then", "text": "항목나", "children": [
                            {"type": "item", "text": "원문", "role": "raw"},
                            {"type": "item", "text": "원문둘", "role": "raw"}
                        ]}
                    ]}
                ]}
            ]}
        ]}
        """)
    }

    /// A `list` at the very top of the document (no enclosing section, `before == nil` at
    /// the start) with a `start` gap and a per-item `n` override, to exercise the
    /// recognizer's index-override quirk (`before.index + 1` wins over an explicit `n`
    /// when the immediately preceding line shares the same `.half_bracket_alpha`
    /// indexType) while list-item transparency keeps every item a document root.
    func testParagraphAdapter_matchesRecognize_topLevelListWithStartAndNGaps() throws {
        try assertParagraphAdapterMatchesRecognize("""
        {"part": 9999, "nodes": [
            {"type": "list", "ordered": true, "start": 3, "items": [
                {"text": "목록셋"},
                {"text": "목록다섯", "n": 5},
                {"text": "목록여섯"}
            ]}
        ]}
        """)
    }

    /// Two top-level sections at the same natural depth, the second with an explicit `n`
    /// gap — same index-override quirk as the list test above, for numbered sections.
    func testParagraphAdapter_matchesRecognize_topLevelSectionsWithNGap() throws {
        try assertParagraphAdapterMatchesRecognize("""
        {"part": 9999, "nodes": [
            {"type": "section", "title": "A"},
            {"type": "section", "title": "B", "n": 5}
        ]}
        """)
    }

    /// Same equivalence proof, run over the earlier hand-traced fixture (section -> section
    /// -> term -> dash item -> then item -> ordered list with several items), which exercises list items nested under a `then` item.
    func testParagraphAdapter_matchesRecognizeOfRenderedText_forHandTracedFixture() throws {
        let json = """
        {"part": 9999, "nodes": [
            {"type": "section", "title": "대분류", "children": [
                {"type": "section", "title": "중분류", "children": [
                    {"type": "term", "label": "정의", "text": "이것은 설명이다", "children": [
                        {"type": "item", "text": "항목가", "children": [
                            {"type": "item", "role": "then", "text": "항목나", "children": [
                                {"type": "list", "ordered": true, "items": [
                                    {"text": "목록하나"},
                                    {"text": "목록둘"},
                                    {"text": "목록셋"}
                                ]}
                            ]}
                        ]}
                    ]}
                ]}
            ]}
        ]}
        """

        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(json.utf8))
        let rendered = ContentTreeRenderer.render(document.nodes)
        let reference = LSDocumentRecognizer.shared.recognize(doc: rendered)
        let adapted = ContentParagraphAdapter.paragraphs(for: document.nodes)

        XCTAssertEqual(flattenFull(adapted).map(\.text), flattenFull(reference).map(\.text))
        XCTAssertEqual(flattenFull(adapted).map(\.level), flattenFull(reference).map(\.level))
        XCTAssertEqual(flattenFull(adapted).map(\.indexType), flattenFull(reference).map(\.indexType))
        XCTAssertEqual(flattenFull(adapted).map(\.index), flattenFull(reference).map(\.index))

        // And the parent chain RNQuestionInfo.text actually walks reads the same way: the
        // deepest "then" item's ancestor chain should read term -> section -> section.
        func findFirst(_ paragraphs: [LSDocumentRecognizer.LSDocumentParagraph], where predicate: (LSDocumentRecognizer.LSDocumentParagraph) -> Bool) -> LSDocumentRecognizer.LSDocumentParagraph? {
            for p in paragraphs {
                if predicate(p) { return p }
                if let found = findFirst(p.children, where: predicate) { return found }
            }
            return nil
        }
        let thenItem = try XCTUnwrap(findFirst(adapted) { $0.indexType == .next })
        var chain: [String] = []
        var walker: LSDocumentRecognizer.LSDocumentParagraph? = thenItem
        while let current = walker {
            chain.append(current.text)
            walker = current.parent
        }
        XCTAssertEqual(chain, ["항목나", "항목가", "정의 : 이것은 설명이다", "중분류", "대분류"])
    }

    /// docs/plans/content-tree.md P3's whole reason to exist: once a part's JSON is *fixed*
    /// (e.g. a `◎` term correctly nested under the section it belongs to, where the old
    /// heuristic parser would have hoisted it to a sibling of that section — see plan §7 /
    /// `ContentParagraphAdapter`'s file header), the adapter must follow the JSON tree, not
    /// rebuild the old (wrong) shape. This synthetic fixture models exactly that: a term
    /// nested two sections deep, in a position the legacy line-by-line heuristic would NOT
    /// have produced on its own (a section with no numbered/bulleted content before the
    /// term, so the heuristic's `indexingParent`/`sibilsHasChild` dance can drift) — the
    /// adapter must keep it as the section's own child because that is what the JSON says.
    func testParagraphAdapter_followsFixedTreeStructure_notTheOldHeuristic() throws {
        let json = """
        {"part": 9999, "nodes": [
            {"type": "section", "title": "대분류", "children": [
                {"type": "section", "title": "중분류", "children": [
                    {"type": "term", "label": "정의", "text": "이것은 고쳐진 위치다"}
                ]}
            ]}
        ]}
        """
        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(json.utf8))
        let adapted = ContentParagraphAdapter.paragraphs(for: document.nodes)

        // Root is "대분류"; its only child is "중분류"; the term is "중분류"'s own child —
        // exactly the JSON's nesting, three levels deep.
        let root = try XCTUnwrap(adapted.first)
        XCTAssertEqual(root.text, "대분류")
        XCTAssertEqual(root.level, 0)

        let middle = try XCTUnwrap(root.children.first)
        XCTAssertEqual(middle.text, "중분류")
        XCTAssertEqual(middle.level, 1)

        let term = try XCTUnwrap(middle.children.first)
        XCTAssertEqual(term.indexType, .term)
        XCTAssertEqual(term.text, "정의 : 이것은 고쳐진 위치다")
        XCTAssertEqual(term.level, 2)
        XCTAssertTrue(term.parent === middle, "adapter must attach the term to its JSON parent, not re-derive a parent heuristically")

        // Sanity: this is genuinely the tree a naive render-then-reparse would NOT be
        // guaranteed to reproduce once nodes move around under P3 — the adapter path taken
        // here never renders text or calls `LSDocumentRecognizer.recognize` at all.
        XCTAssertEqual(root.children.count, 1)
        XCTAssertEqual(middle.children.count, 1)
    }

    // MARK: - Quiz excludes notes

    private func allTexts(_ paragraphs: [LSDocumentRecognizer.LSDocumentParagraph]) -> [String] {
        paragraphs.flatMap { [$0.text] + allTexts($0.children) }
    }

    private let noteFixture = """
    {"part": 9999, "nodes": [
        {"type": "section", "title": "대분류", "children": [
            {"type": "term", "label": "용어가", "text": "설명가", "children": [
                {"type": "note", "kind": "mnemonic", "text": "암기문구"}
            ]},
            {"type": "term", "label": "용어나", "text": "설명나", "children": [
                {"type": "item", "text": "항목가"},
                {"type": "note", "kind": "tip", "text": "참고문구"},
                {"type": "item", "text": "항목나", "children": [
                    {"type": "note", "kind": "formula", "text": "공식문구"}
                ]}
            ]},
            {"type": "note", "kind": "mnemonic", "text": "최상위암기"}
        ]}
    ]}
    """

    func testParagraphAdapter_excludesNotesEverywhere() throws {
        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(noteFixture.utf8))
        let adapted = ContentParagraphAdapter.paragraphs(for: document.nodes)
        let texts = allTexts(adapted)

        for needle in ["암기문구", "참고문구", "공식문구", "최상위암기", "※ 암기법"] {
            XCTAssertFalse(texts.contains { $0.contains(needle) }, "note text leaked into quiz paragraphs: \(needle)")
        }
        XCTAssertEqual(texts, ["대분류", "용어가 : 설명가", "용어나 : 설명나", "항목가", "항목나"])
    }

    func testParagraphAdapter_parentWithOnlyNoteChildrenHasNoChildren() throws {
        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(noteFixture.utf8))
        let adapted = ContentParagraphAdapter.paragraphs(for: document.nodes)
        let section = try XCTUnwrap(adapted.first)
        let onlyNote = try XCTUnwrap(section.children.first { $0.text.hasPrefix("용어가") })
        XCTAssertTrue(onlyNote.children.isEmpty, "a term whose only child is a note must not become a question")
        let withItems = try XCTUnwrap(section.children.first { $0.text.hasPrefix("용어나") })
        XCTAssertEqual(withItems.children.map(\.text), ["항목가", "항목나"])
        XCTAssertTrue(try XCTUnwrap(withItems.children.last).children.isEmpty)
    }

    func testParagraphAdapter_matchesRecognize_ofTreeWithNotesStripped() throws {
        // Removing notes from the JSON and running the full equivalence proof shows the
        // adapter's remaining shape (incl. index bookkeeping) is unchanged by the skip.
        try assertParagraphAdapterMatchesRecognize("""
        {"part": 9999, "nodes": [
            {"type": "section", "title": "대분류", "children": [
                {"type": "term", "label": "용어나", "text": "설명나", "children": [
                    {"type": "item", "text": "항목가"},
                    {"type": "item", "text": "항목나"}
                ]}
            ]}
        ]}
        """)
    }

    func testRenderer_stillRendersNotesForDisplay() throws {
        let document = try JSONDecoder().decode(ContentDocument.self, from: Data(noteFixture.utf8))
        let rendered = ContentTreeRenderer.render(document.nodes)
        XCTAssertTrue(rendered.contains("(※ 암기법 : 암기문구)"))
        XCTAssertTrue(rendered.contains("* 참고문구"))
        XCTAssertTrue(rendered.contains("* 공식문구"))
        XCTAssertTrue(rendered.contains("(※ 암기법 : 최상위암기)"))
        XCTAssertTrue(ContentRendering.displayText(for: noteFixture).contains("암기문구"))
    }
}
