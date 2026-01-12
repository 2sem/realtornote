import SwiftUI
import SwiftData

struct SubjectScreen: View {
    @EnvironmentObject private var adManager: SwiftUIAdManager
    @AppStorage(LSDefaults.Keys.LaunchCount) private var launchCount: Int = 0
    
    let subject: Subject
    @Binding var selectedChapter: Chapter?
    @Binding var showFavorites: Bool
    let initialPartSeq: Int?
    
    @State private var previousChapterId: Int? = nil

    var body: some View {
        Group {
            if let chapter = selectedChapter {
                PartListScreen(chapter: chapter, initialPartSeq: initialPartSeq)
                    .id("\(chapter.id)-\(initialPartSeq ?? 0)") // Force recreation when initialPartSeq changes
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
        .onChange(of: selectedChapter?.id) { oldValue, newValue in
            // Show ad when chapter changes (but not on initial load)
            guard let newValue = newValue,
                  let previousId = previousChapterId,
                  newValue != previousId else {
                // Set initial value
                if previousChapterId == nil {
                    previousChapterId = newValue
                }
                return
            }
            
            presentFullAdThen {
                previousChapterId = newValue
            }
        }
        .onChange(of: initialPartSeq) { oldValue, newValue in
            print("📗 SubjectScreen.onChange - initialPartSeq changed from \(oldValue ?? -1) to \(newValue ?? -1)")
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
    NavigationStack {
        SubjectScreen(
            subject: Subject(id: 1, name: "민법 및 민사특별법", detail: "Test"),
            selectedChapter: .constant(nil),
            showFavorites: .constant(false),
            initialPartSeq: nil
        )
    }
}
