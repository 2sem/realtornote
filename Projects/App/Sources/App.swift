import SwiftUI
import SwiftData

@main
struct RealtorNoteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isSplashDone = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 메인 화면 (루트)
                NavigationStack {
                    MainScreen()
                }
                
                // 스플래시 오버레이
                if !isSplashDone {
                    SplashScreen(isDone: $isSplashDone)
                        .transition(.opacity)
                }
            }
        }.modelContainer(for: [Subject.self, Chapter.self, Part.self, Favorite.self, Alarm.self],
                         inMemory: false,
                         isAutosaveEnabled: false,
                         isUndoEnabled: true)
    }
}
