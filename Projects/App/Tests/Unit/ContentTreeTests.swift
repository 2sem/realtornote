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
}
