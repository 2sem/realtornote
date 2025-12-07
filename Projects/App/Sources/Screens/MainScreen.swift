import SwiftUI
import SwiftData

struct MainScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.id) private var subjects: [Subject]
    @AppStorage("LastSubject") private var lastSubject: Int = 0
    @State private var selectedTab: Int = 0
    @State var isFirstAppear: Bool = true
    @State private var showFavorites: Bool = false
    @State private var showQuiz: Bool = false
    @State private var selectedChapters: [Int: Chapter] = [:] // Track selected chapter per subject ID
    
    // Current subject based on selectedTab
    private var currentSubject: Subject? {
        guard selectedTab < subjects.count else { return nil }
        return subjects[selectedTab]
    }
    
    // Sorted chapters for current subject
    private var currentChapters: [Chapter] {
        currentSubject?.chapters.sorted { $0.id < $1.id } ?? []
    }
    
    // Binding for current subject's selected chapter
    private var currentSelectedChapter: Binding<Chapter?> {
        Binding(
            get: {
                guard let subject = currentSubject else { return nil }
                return selectedChapters[subject.id]
            },
            set: { newValue in
                guard let subject = currentSubject else { return }
                selectedChapters[subject.id] = newValue
                // Save to defaults
                if let chapter = newValue {
                    LSDefaults.setLastChapter(subject: subject.id, value: chapter.id)
                }
            }
        )
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                        ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                            SubjectScreen(
                                subject: subject,
                                selectedChapter: Binding(
                                    get: { selectedChapters[subject.id] },
                                    set: { 
                                        selectedChapters[subject.id] = $0
                                        if let chapter = $0 {
                                            LSDefaults.setLastChapter(subject: subject.id, value: chapter.id)
                                        }
                                    }
                                ),
                                showFavorites: $showFavorites
                            )
                            .tabItem {
                                Label(subject.name, systemImage: "book.closed.fill")
                            }
                            .tag(index)
                        }
                    }
                    
                    // External links bar above tab bar
                    ExternalLinksBar()
                }
            }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !currentChapters.isEmpty {
                    ChapterPicker(
                        chapters: currentChapters,
                        selectedChapter: currentSelectedChapter
                    )
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    // Quiz button
                    Button {
                        showQuiz = true
                    } label: {
                        Image(systemName: "questionmark.text.page")
                            .foregroundColor(.accentColor)
                    }
                    .disabled(currentSelectedChapter.wrappedValue == nil)
                    
                    // Favorites button
                    Button {
                        showFavorites = true
                    } label: {
                        Image(systemName: "book")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .onAppear {
            guard isFirstAppear else {
                return
            }
            
            // 마지막으로 본 과목으로 이동
            selectedTab = min(lastSubject, subjects.count - 1)
            
            // 각 과목의 마지막 챕터 복원
            for subject in subjects {
                let sortedChapters = subject.chapters.sorted { $0.id < $1.id }
                let lastChapterId = LSDefaults.LastChapter[subject.id.description] ?? sortedChapters.first?.id ?? 1
                selectedChapters[subject.id] = sortedChapters.first { $0.id == lastChapterId } ?? sortedChapters.first
            }
            
            isFirstAppear = false
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // 선택한 과목 저장
            lastSubject = newValue
        }
        .sheet(isPresented: $showFavorites) {
            NavigationStack {
                FavoritesScreen()
            }
        }
        .sheet(isPresented: $showQuiz) {
            if let chapter = currentSelectedChapter.wrappedValue {
                QuizScreen(chapter: chapter)
            }
        }
    }
}

#Preview {
    MainScreen()
        .modelContainer(for: [Subject.self, Chapter.self, Part.self, Favorite.self, Alarm.self])
}
