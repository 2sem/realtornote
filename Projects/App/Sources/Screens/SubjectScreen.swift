import SwiftUI
import SwiftData

struct SubjectScreen: View {
    let subject: Subject
    @Binding var selectedChapter: Chapter?
    @Binding var showFavorites: Bool

    var body: some View {
        Group {
            if let chapter = selectedChapter {
                PartListScreen(chapter: chapter)
            } else {
                VStack {
                    Spacer()
                    Text("챕터를 선택하세요")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SubjectScreen(
            subject: Subject(id: 1, name: "민법 및 민사특별법", detail: "Test"),
            selectedChapter: .constant(nil),
            showFavorites: .constant(false)
        )
    }
}
