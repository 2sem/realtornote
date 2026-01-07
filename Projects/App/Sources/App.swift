import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct RealtorNoteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isSplashDone = false
    @State private var isSetupDone = false
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var adManager = SwiftUIAdManager()

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
            .environmentObject(adManager)
            .onAppear {
                setupAds()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
        }.modelContainer(for: [Subject.self, Chapter.self, Part.self, Favorite.self, Alarm.self],
                         inMemory: false,
                         isAutosaveEnabled: false,
                         isUndoEnabled: true)
    }
    
    private func setupAds() {
        guard !isSetupDone else {
            return
        }
        
        MobileAds.shared.start { [weak adManager] status in
            guard let adManager = adManager else { return }
            
            adManager.setup()
            
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["8a00796a760e384800262e0b7c3d08fe"]
            
            #if DEBUG
            adManager.prepare(interstitialUnit: .full, interval: 60.0)
            adManager.prepare(openingUnit: .launch, interval: 60.0)
            #else
            adManager.prepare(interstitialUnit: .full, interval: 60.0 * 60)
            adManager.prepare(openingUnit: .launch, interval: 60.0 * 5)
            #endif
            adManager.prepare(rewardUnit: .reward)
            adManager.canShowFirstTime = true
        }
        
        isSetupDone = true
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            handleAppDidBecomeActive()
        case .inactive:
            break
        case .background:
            break
        @unknown default:
            break
        }
    }
    
    private func handleAppDidBecomeActive() {
        print("scene become active")
        Task {
            defer {
                LSDefaults.increaseLaunchCount()
            }
            
            await adManager.requestAppTrackingIfNeed()
            await adManager.show(unit: .launch)
        }
    }
}
