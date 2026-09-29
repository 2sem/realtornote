import Foundation

/// Decoded shape of `Content/manifest.json` — the version tag and subject order.
struct ContentManifest: Decodable {
    let version: String
    let subjects: [Int]
}

/// Decoded shape of `Content/subjects/{id}.json` — a subject's chapter/part outline.
/// Order = array order; `seq` is derived from the index, not stored.
struct ContentSubjectOutline: Decodable {
    struct Chapter: Decodable {
        struct Part: Decodable {
            let id: Int
            let name: String
        }

        let id: Int
        let name: String
        let parts: [Part]
    }

    let id: Int
    let name: String
    let detail: String
    let chapters: [Chapter]
}

enum ContentLoaderError: LocalizedError {
    case contentFolderNotFound
    case fileNotFound(String)
    case decodingFailed(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .contentFolderNotFound:
            return "Content 폴더를 찾을 수 없습니다. Content.zip이 해제되지 않았을 수 있습니다."
        case .fileNotFound(let path):
            return "Content 파일을 찾을 수 없습니다: \(path)"
        case .decodingFailed(let path, let underlying):
            return "Content 파일을 읽는 데 실패했습니다: \(path) (\(underlying.localizedDescription))"
        }
    }
}

/// Loads the folder-based study content (`Content/`) bundled as a resource, replacing the
/// Excel (xlsx) source. See `ContentSyncService` for how these DTOs get synced into SwiftData.
struct ContentLoader {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    private var contentRootURL: URL? {
        bundle.url(forResource: "Content", withExtension: nil)
    }

    func loadManifest() throws -> ContentManifest {
        let root = try requireContentRoot()
        return try decode(ContentManifest.self, at: root.appendingPathComponent("manifest.json"))
    }

    func loadSubjectOutline(id: Int) throws -> ContentSubjectOutline {
        let root = try requireContentRoot()
        let path = "subjects/\(id).json"
        return try decode(ContentSubjectOutline.self, at: root.appendingPathComponent(path), relativePath: path)
    }

    /// The exact UTF-8 body of a part — never trimmed, content is used byte-for-byte.
    ///
    /// Content tree migration (docs/plans/content-tree.md): parts move to `parts/<id>.json`
    /// one at a time, so both formats coexist. Prefers `<id>.json` when it exists in the
    /// bundle, else falls back to the legacy `<id>.txt`. Either way the raw string is stored
    /// as-is into `Part.content` — no SwiftData schema change; `String.isContentTreeJSON`
    /// (checked by consumers, see `ContentRendering`) tells JSON from legacy text by content.
    func loadPartContent(id: Int) throws -> String {
        let root = try requireContentRoot()

        let jsonRelativePath = "parts/\(id).json"
        let jsonURL = root.appendingPathComponent(jsonRelativePath)
        if FileManager.default.fileExists(atPath: jsonURL.path) {
            return try readUTF8(at: jsonURL, relativePath: jsonRelativePath)
        }

        let txtRelativePath = "parts/\(id).txt"
        let txtURL = root.appendingPathComponent(txtRelativePath)
        return try readUTF8(at: txtURL, relativePath: txtRelativePath)
    }

    private func readUTF8(at url: URL, relativePath: String) throws -> String {
        guard let data = try? Data(contentsOf: url) else {
            throw ContentLoaderError.fileNotFound(relativePath)
        }
        guard let content = String(data: data, encoding: .utf8) else {
            throw ContentLoaderError.decodingFailed(
                relativePath,
                underlying: CocoaError(.fileReadUnknownStringEncoding)
            )
        }
        return content
    }

    private func requireContentRoot() throws -> URL {
        guard let root = contentRootURL else {
            throw ContentLoaderError.contentFolderNotFound
        }
        return root
    }

    private func decode<T: Decodable>(_ type: T.Type, at url: URL, relativePath: String? = nil) throws -> T {
        let path = relativePath ?? url.lastPathComponent
        guard let data = try? Data(contentsOf: url) else {
            throw ContentLoaderError.fileNotFound(path)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ContentLoaderError.decodingFailed(path, underlying: error)
        }
    }
}
