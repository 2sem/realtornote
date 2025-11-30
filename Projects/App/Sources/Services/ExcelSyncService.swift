import Foundation
import SwiftData
import StringLogger

@MainActor
class ExcelSyncService {
    private let excelController = RNExcelController.Default
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func syncIfNeeded(force: Bool = false) async throws {
        "[ExcelSync] syncExcelToSwiftData started, force: \(force)".trace()
        
        let needUpdate = excelController.needToUpdate
        
        "[ExcelSync] Check - Force: \(force), Excel needsUpdate: \(needUpdate)".trace()
        
        guard force || needUpdate else {
            "[ExcelSync] SwiftData has data and Excel is up to date, no sync needed".trace()
            return
        }
        
        if force {
            "[ExcelSync] Force sync requested".trace()
        } else {
            "[ExcelSync] Excel needs update, starting sync".trace()
        }
        
        "[ExcelSync] Loading Excel file".trace()
        excelController.loadFromFlie()
        
        let isFirstSync = force || LSDefaults.DataVersion.isEmpty || LSDefaults.DataVersion == "0.0"
        let excelSubjects = excelController.subjects
        
        "[ExcelSync] Loaded \(excelSubjects.count) subjects from Excel, isFirstSync: \(isFirstSync)".trace()
        
        if isFirstSync {
            "[ExcelSync] First sync detected, creating all data".trace()
            for excelSubject in excelSubjects {
                let subject = Subject(from: excelSubject)
                context.insert(subject)
                "[ExcelSync] Created new subject: \(excelSubject.name)".trace()
                
                createChapters(excelSubject.chapters, subject: subject)
            }
        } else {
            "[ExcelSync] Updating existing data".trace()
            for excelSubject in excelSubjects {
                var subject = try findSubject(id: excelSubject.id)
                
                if subject == nil {
                    subject = Subject(from: excelSubject)
                    context.insert(subject!)
                    "[ExcelSync] Created new subject: \(excelSubject.name)".trace()
                } else {
                    subject?.name = excelSubject.name
                    subject?.detail = excelSubject.detail
                    "[ExcelSync] Updated subject: \(excelSubject.name)".trace()
                }
                
                try syncChapters(excelSubject.chapters, subject: subject!)
            }
        }
        
        try context.save()
        LSDefaults.DataVersion = excelController.version
        "[ExcelSync] Excel sync completed, version: \(excelController.version)".trace()
    }
    
    private func createChapters(_ excelChapters: [RNExcelChapter], subject: Subject) {
        "[ExcelSync] Creating \(excelChapters.count) chapters for subject: \(subject.name)".trace()
        for excelChapter in excelChapters {
            let chapter = Chapter(from: excelChapter, subject: subject)
            context.insert(chapter)
            subject.chapters.append(chapter)
            
            createParts(excelChapter.parts, chapter: chapter)
        }
    }
    
    private func createParts(_ excelParts: [RNExcelPart], chapter: Chapter) {
        "[ExcelSync] Creating \(excelParts.count) parts for chapter: \(chapter.name)".trace()
        for excelPart in excelParts {
            let part = Part(from: excelPart, chapter: chapter)
            context.insert(part)
            chapter.parts.append(part)
        }
    }
    
    private func syncChapters(_ excelChapters: [RNExcelChapter], subject: Subject) throws {
        "[ExcelSync] Syncing \(excelChapters.count) chapters for subject: \(subject.name)".trace()
        for excelChapter in excelChapters {
            var chapter = try findChapter(id: excelChapter.id)
            
            if chapter == nil {
                chapter = Chapter(from: excelChapter, subject: subject)
                context.insert(chapter!)
                subject.chapters.append(chapter!)
                "[ExcelSync] Created new chapter: \(excelChapter.name)".trace()
            } else {
                chapter?.name = excelChapter.name
                chapter?.seq = excelChapter.seq
                chapter?.subject = subject
                "[ExcelSync] Updated chapter: \(excelChapter.name)".trace()
            }
            
            try syncParts(excelChapter.parts, chapter: chapter!)
        }
    }
    
    private func syncParts(_ excelParts: [RNExcelPart], chapter: Chapter) throws {
        "[ExcelSync] Syncing \(excelParts.count) parts for chapter: \(chapter.name)".trace()
        for excelPart in excelParts {
            var part = try findPart(id: excelPart.id)
            
            if part == nil {
                part = Part(from: excelPart, chapter: chapter)
                context.insert(part!)
                chapter.parts.append(part!)
            } else {
                part?.name = excelPart.name
                part?.seq = excelPart.seq
                part?.content = excelPart.content
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
