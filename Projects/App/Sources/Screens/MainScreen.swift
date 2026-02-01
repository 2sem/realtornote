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
    
    // Favorites navigation state
    @State private var targetPartSeq: Int? = nil // Part to navigate to from favorites
    @State private var isNavigatingFromFavorite: Bool = false // Flag to prevent premature clearing
    @State private var pendingFavoriteNavigation: FavoriteNavigationResult? = nil
    
    private let favoriteNavigator: FavoriteNavigating = FavoriteNavigator()
    
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
                .onAppear {
                    if #unavailable(iOS 26.0) {
                        let appearance = UITabBarAppearance()
                        appearance.configureWithDefaultBackground()
                        appearance.backgroundColor = UIColor(Color(red: 0.506, green: 0.831, blue: 0.980))

                        // Dark blue colors for better visibility on sky blue background (iOS 18-25 only)
                        let itemAppearance = UITabBarItemAppearance()
                        let darkBlue = UIColor(red: 0.004, green: 0.341, blue: 0.608, alpha: 1.0)
                        itemAppearance.normal.iconColor = darkBlue.withAlphaComponent(0.6)
                        itemAppearance.normal.titleTextAttributes = [.foregroundColor: darkBlue.withAlphaComponent(0.6)]
                        itemAppearance.selected.iconColor = darkBlue
                        itemAppearance.selected.titleTextAttributes = [.foregroundColor: darkBlue]

                        appearance.stackedLayoutAppearance = itemAppearance
                        appearance.inlineLayoutAppearance = itemAppearance
                        appearance.compactInlineLayoutAppearance = itemAppearance

                        UITabBar.appearance().standardAppearance = appearance
                        UITabBar.appearance().scrollEdgeAppearance = appearance
                    }
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
            // 선택한 과목 저장
            lastSubject = newValue
            // 현재 과목의 선택된 챕터 로드 (없는 경우만)
            loadSelectedChapterForCurrentSubject()
            
            // Clear target part only when switching tabs manually (not from favorite navigation)
            if oldValue != newValue && !isNavigatingFromFavorite {
                targetPartSeq = nil
            }
        }
        .sheet(isPresented: $showFavorites, onDismiss: applyPendingFavoriteNavigation) {
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
        guard let navigation = favoriteNavigator.navigationInfo(for: favorite, in: subjects) else {
            print("❌ Failed to resolve navigation info for favorite id: \(favorite.id)")
            return
        }
        
        // Store navigation intent and set flag
        pendingFavoriteNavigation = navigation
        isNavigatingFromFavorite = true
        showFavorites = false
    }
    
    private func applyPendingFavoriteNavigation() {
        guard let navigation = pendingFavoriteNavigation else {
            isNavigatingFromFavorite = false
            return
        }
        
        guard navigation.subjectIndex < subjects.count else {
            print("❌ Pending navigation subject index out of bounds: \(navigation.subjectIndex)")
            pendingFavoriteNavigation = nil
            isNavigatingFromFavorite = false
            return
        }
        
        // Apply navigation state
        selectedTab = navigation.subjectIndex
        selectedChapters[navigation.subjectId] = navigation.chapter
        targetPartSeq = navigation.partSeq
        
        // Clear pending intent and reset flag on next run loop so onChange can observe the flag
        Task { @MainActor in
            pendingFavoriteNavigation = nil
            isNavigatingFromFavorite = false
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
