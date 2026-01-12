import SwiftUI
import SwiftData

struct MainScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.id) private var subjects: [Subject]
    @AppStorage("LastSubject") private var lastSubject: Int = 0
    @State private var selectedTab: Int = 0
    @State private var showFavorites: Bool = false
    @State private var showQuiz: Bool = false
    @State private var showAlarmList: Bool = false
    @State private var selectedChapters: [Int: Chapter] = [:] // Track selected chapter per subject ID
    @State private var keyboardState = KeyboardState() // Keyboard visibility state
    @State private var targetPartSeq: Int? = nil // Part to navigate to from favorites
    @State private var isNavigatingFromFavorite: Bool = false // Flag to prevent premature clearing
    
    @EnvironmentObject private var adManager: SwiftUIAdManager
    @AppStorage(LSDefaults.Keys.LaunchCount) private var launchCount: Int = 0
    
    private let backgroundColor = Color(red: 0.506, green: 0.831, blue: 0.980)
    
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
                            showFavorites: $showFavorites,
                            initialPartSeq: selectedTab == index ? targetPartSeq : nil
                        )
                        .tag(index)
                        .tabItem {
                            Label(subject.name, systemImage: selectedTab == index ? "book" : "text.book.closed.fill")
                        }
                    }
                }

                // External links bar above tab bar (hidden when keyboard visible)
                if !keyboardState.isVisible {
                    ExternalLinksBar()
                }
            }
        }
        .environment(keyboardState)
        .scrollContentBackground(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAlarmList = true
                } label: {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }

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
                        presentFullAdThen {
                            showQuiz = true
                        }
                    } label: {
                        Image(systemName: "questionmark.text.page")
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(currentSelectedChapter.wrappedValue == nil)
                    
                    // Favorites button
                    Button {
                        showFavorites = true
                    } label: {
                        Image(systemName: "book")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
        .task {
            guard !subjects.isEmpty else {
                return
            }

            // 마지막으로 본 과목으로 이동
            selectedTab = max(0, min(lastSubject, subjects.count - 1))

            // 현재 과목의 선택된 챕터 로드 (없는 경우만)
            loadSelectedChapterForCurrentSubject()
        }
        .onChange(of: !subjects.isEmpty, { _, newValue in
            guard newValue else { return }
            
            loadSelectedChapterForCurrentSubject()
        })
        .onChange(of: selectedTab) { oldValue, newValue in
            print("📱 MainScreen.onChange(selectedTab): \(oldValue) -> \(newValue), isNavigatingFromFavorite: \(isNavigatingFromFavorite)")
            
            // 선택한 과목 저장
            lastSubject = newValue
            // 현재 과목의 선택된 챕터 로드 (없는 경우만)
            loadSelectedChapterForCurrentSubject()
            
            // Clear target part only when switching tabs manually (not from favorite navigation)
            if oldValue != newValue && !isNavigatingFromFavorite {
                print("📱 Clearing targetPartSeq (manual tab switch)")
                targetPartSeq = nil
            }
        }
        .sheet(isPresented: $showFavorites) {
            NavigationStack {
                FavoritesScreen(onSelectFavorite: handleFavoriteSelection)
            }
        }
        .sheet(isPresented: $showQuiz) {
            if let chapter = currentSelectedChapter.wrappedValue {
                QuizScreen(chapter: chapter)
            }
        }
        .sheet(isPresented: $showAlarmList) {
            AlarmListScreen()
        }
    }
    
    func loadSelectedChapterForCurrentSubject() {
        // Don't load if subjects are empty (still being inserted during migration)
        guard !subjects.isEmpty else { return }
        guard let subject = currentSubject else { return }
        
        // Only load if not already loaded
        guard selectedChapters[subject.id] == nil else { return }
        
        let sortedChapters = subject.chapters.sorted { $0.id < $1.id }
        let lastChapters = LSDefaults.LastChapter
        let lastChapterId = lastChapters[subject.id.description] ?? sortedChapters.first?.id ?? 1
        selectedChapters[subject.id] = sortedChapters.first { $0.id == lastChapterId } ?? sortedChapters.first
    }
    
    private func handleFavoriteSelection(_ favorite: Favorite) {
        print("🔍 handleFavoriteSelection called for favorite id: \(favorite.id)")
        
        // Get the part, chapter, and subject from the favorite
        let part = favorite.part
        print("🔍 Part: id=\(part.id), seq=\(part.seq), name=\(part.name)")
        
        guard let chapter = part.chapter else {
            print("❌ Chapter is nil for part \(part.id)")
            return
        }
        print("🔍 Chapter: id=\(chapter.id), seq=\(chapter.seq), name=\(chapter.name)")
        
        guard let subject = chapter.subject else {
            print("❌ Subject is nil for chapter \(chapter.id)")
            return
        }
        print("🔍 Subject: id=\(subject.id), name=\(subject.name)")
        
        // Find the subject index
        guard let subjectIndex = subjects.firstIndex(where: { $0.id == subject.id }) else {
            print("❌ Could not find subject index for subject id: \(subject.id)")
            return
        }
        print("🔍 Subject index: \(subjectIndex)")
        
        // Set navigation flag
        isNavigatingFromFavorite = true
        
        // Dismiss favorites sheet
        print("🔍 Dismissing favorites sheet")
        showFavorites = false
        
        // Navigate to the correct subject, chapter, and part
        print("🔍 Scheduling navigation after 0.3s delay")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("🔍 Navigating to subject \(subjectIndex), chapter \(chapter.id), part \(part.seq)")
            
            // Switch to correct subject tab
            self.selectedTab = subjectIndex
            
            // Set the chapter
            self.selectedChapters[subject.id] = chapter
            
            // Set target part for navigation
            self.targetPartSeq = part.seq
            
            print("✅ Navigation state set: tab=\(self.selectedTab), chapter=\(chapter.id), targetPart=\(part.seq)")
            
            // Clear navigation flag and targetPartSeq after views have had time to react
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("🧹 Clearing navigation state")
                self.isNavigatingFromFavorite = false
                self.targetPartSeq = nil
            }
        }
    }
    
    private func presentFullAdThen(_ action: @escaping () -> Void) {
        guard launchCount > 1 else {
            action()
            return
        }
        
        Task {
            await adManager.requestAppTrackingIfNeed()
            await adManager.show(unit: .full)
            action()
        }
    }
}

#Preview {
    MainScreen()
        .modelContainer(for: [Subject.self, Chapter.self, Part.self, Favorite.self, Alarm.self])
}
