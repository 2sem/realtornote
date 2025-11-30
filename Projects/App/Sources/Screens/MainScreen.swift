import SwiftUI
import SwiftData

struct MainScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.id) private var subjects: [Subject]
    @AppStorage("LastSubject") private var lastSubject: Int = 0
    @State private var selectedTab: Int = 0
    @State var isFirstAppear: Bool = true

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                SubjectScreen(subject: subject)
                    .tabItem {
                        Label(subject.name, systemImage: "book.closed.fill")
                    }
                    .tag(index)
            }
        }
        .onAppear {
            guard isFirstAppear else {
                return
            }
            
            // 마지막으로 본 과목으로 이동
            selectedTab = min(lastSubject, subjects.count - 1)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // 선택한 과목 저장
            lastSubject = newValue
        }
    }
}

#Preview {
    MainScreen()
        .modelContainer(for: [Subject.self, Chapter.self, Part.self, Favorite.self, Alarm.self])
}
