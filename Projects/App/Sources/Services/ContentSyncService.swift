import Foundation
import SwiftData
import StringLogger

/// Syncs the folder-based study content (`Content/`) into SwiftData, replacing
/// `ExcelSyncService`/`RNExcelController` as the live sync path. Same semantics:
/// version-gated, first-sync creates everything, otherwise upserts by id and never deletes.
@MainActor
class ContentSyncService {
    private let loader: ContentLoader
    private let context: ModelContext

    init(context: ModelContext, loader: ContentLoader = ContentLoader()) {
        self.context = context
        self.loader = loader
    }

    func syncIfNeeded(force: Bool = false) async throws {
        "[ContentSync] syncIfNeeded started, force: \(force)".trace()

        let manifest = try loader.loadManifest()
        let needUpdate = LSDefaults.DataVersion.compare(manifest.version, options: .numeric) == .orderedAscending

        "[ContentSync] Check - Force: \(force), Content needsUpdate: \(needUpdate)".trace()

        guard force || needUpdate else {
            "[ContentSync] SwiftData has data and Content is up to date, no sync needed".trace()
            return
        }

        if force {
            "[ContentSync] Force sync requested".trace()
        } else {
            "[ContentSync] Content needs update, starting sync".trace()
        }

        let isFirstSync = force || LSDefaults.DataVersion.isEmpty || LSDefaults.DataVersion == "0.0"
        let subjectOutlines = try manifest.subjects.map { try loader.loadSubjectOutline(id: $0) }

        "[ContentSync] Loaded \(subjectOutlines.count) subjects from Content, isFirstSync: \(isFirstSync)".trace()

        if isFirstSync {
            "[ContentSync] First sync detected, creating all data".trace()
            for outline in subjectOutlines {
                let subject = Subject(id: outline.id, name: outline.name, detail: outline.detail)
                context.insert(subject)
                "[ContentSync] Created new subject: \(outline.name)".trace()

                try createChapters(outline.chapters, subject: subject)
            }
        } else {
            "[ContentSync] Updating existing data".trace()
            for outline in subjectOutlines {
                var subject = try findSubject(id: outline.id)

                if subject == nil {
                    subject = Subject(id: outline.id, name: outline.name, detail: outline.detail)
                    context.insert(subject!)
                    "[ContentSync] Created new subject: \(outline.name)".trace()
                } else {
                    subject?.name = outline.name
                    subject?.detail = outline.detail
                    "[ContentSync] Updated subject: \(outline.name)".trace()
                }

                try syncChapters(outline.chapters, subject: subject!)
            }
        }

        try context.save()
        LSDefaults.DataVersion = manifest.version
        "[ContentSync] Content sync completed, version: \(manifest.version)".trace()
    }

    private func createChapters(_ outlines: [ContentSubjectOutline.Chapter], subject: Subject) throws {
        "[ContentSync] Creating \(outlines.count) chapters for subject: \(subject.name)".trace()
        for (index, outline) in outlines.enumerated() {
            let chapter = Chapter(id: outline.id, seq: index + 1, name: outline.name, subject: subject)
            context.insert(chapter)
            subject.chapters.append(chapter)

            try createParts(outline.parts, chapter: chapter)
        }
    }

    private func createParts(_ outlines: [ContentSubjectOutline.Chapter.Part], chapter: Chapter) throws {
        "[ContentSync] Creating \(outlines.count) parts for chapter: \(chapter.name)".trace()
        for (index, outline) in outlines.enumerated() {
            let content = try loader.loadPartContent(id: outline.id)
            let part = Part(id: outline.id, seq: index + 1, name: outline.name, content: content, chapter: chapter)
            context.insert(part)
            chapter.parts.append(part)
        }
    }

    private func syncChapters(_ outlines: [ContentSubjectOutline.Chapter], subject: Subject) throws {
        "[ContentSync] Syncing \(outlines.count) chapters for subject: \(subject.name)".trace()
        for (index, outline) in outlines.enumerated() {
            var chapter = try findChapter(id: outline.id)
            let seq = index + 1

            if chapter == nil {
                chapter = Chapter(id: outline.id, seq: seq, name: outline.name, subject: subject)
                context.insert(chapter!)
                subject.chapters.append(chapter!)
                "[ContentSync] Created new chapter: \(outline.name)".trace()
            } else {
                chapter?.name = outline.name
                chapter?.seq = seq
                chapter?.subject = subject
                "[ContentSync] Updated chapter: \(outline.name)".trace()
            }

            try syncParts(outline.parts, chapter: chapter!)
        }
    }

    private func syncParts(_ outlines: [ContentSubjectOutline.Chapter.Part], chapter: Chapter) throws {
        "[ContentSync] Syncing \(outlines.count) parts for chapter: \(chapter.name)".trace()
        for (index, outline) in outlines.enumerated() {
            var part = try findPart(id: outline.id)
            let seq = index + 1
            let content = try loader.loadPartContent(id: outline.id)

            if part == nil {
                part = Part(id: outline.id, seq: seq, name: outline.name, content: content, chapter: chapter)
                context.insert(part!)
                chapter.parts.append(part!)
            } else {
                part?.name = outline.name
                part?.seq = seq
                part?.content = content
                part?.chapter = chapter
            }
        }
    }

    private func findSubject(id: Int) throws -> Subject? {
        let descriptor = FetchDescriptor<Subject>(predicate: #Predicate { subject in
            subject.id == id
        })
        return try context.fetch(descriptor).first
    }

    private func findChapter(id: Int) throws -> Chapter? {
        let descriptor = FetchDescriptor<Chapter>(predicate: #Predicate { chapter in
            chapter.id == id
        })
        return try context.fetch(descriptor).first
    }

    private func findPart(id: Int) throws -> Part? {
        let descriptor = FetchDescriptor<Part>(predicate: #Predicate { part in
            part.id == id
        })
        return try context.fetch(descriptor).first
    }
}
