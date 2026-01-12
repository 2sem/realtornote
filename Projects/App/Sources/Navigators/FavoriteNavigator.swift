import Foundation

struct FavoriteNavigationResult {
    let subjectId: Int
    let subjectIndex: Int
    let chapter: Chapter
    let partSeq: Int
}

protocol FavoriteNavigating {
    func navigationInfo(for favorite: Favorite, in subjects: [Subject]) -> FavoriteNavigationResult?
}

struct FavoriteNavigator: FavoriteNavigating {
    func navigationInfo(for favorite: Favorite, in subjects: [Subject]) -> FavoriteNavigationResult? {
        let part = favorite.part
        print("🔍 Part: id=\(part.id), seq=\(part.seq), name=\(part.name)")
        
        guard let chapter = part.chapter else {
            print("❌ Chapter is nil for part \(part.id)")
            return nil
        }
        print("🔍 Chapter: id=\(chapter.id), seq=\(chapter.seq), name=\(chapter.name)")
        
        guard let subject = chapter.subject else {
            print("❌ Subject is nil for chapter \(chapter.id)")
            return nil
        }
        print("🔍 Subject: id=\(subject.id), name=\(subject.name)")
        
        guard let subjectIndex = subjects.firstIndex(where: { $0.id == subject.id }) else {
            print("❌ Could not find subject index for subject id: \(subject.id)")
            return nil
        }
        print("🔍 Subject index: \(subjectIndex)")
        
        return FavoriteNavigationResult(
            subjectId: subject.id,
            subjectIndex: subjectIndex,
            chapter: chapter,
            partSeq: part.seq
        )
    }
}

