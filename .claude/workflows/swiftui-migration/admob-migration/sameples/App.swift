import GoogleMobileAds

@main
struct ProjectNameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var isSplashDone = false
    @State private var isSetupDone = false
    @Environment(\.scenePhase) private var scenePhase
    
    // SceneDelegate의 기능을 SwiftUI ObservableObject로 마이그레이션
    @StateObject private var adManager = SwiftUIAdManager()

    body: some Scene {
        WindowGroup {
            ZStack {
                // 메인 화면 (루트)

                // 스플래시 오버레이
                if !isSplashDone {
                    SplashScreen(isDone: $isSplashDone)
                        .transition(.opacity)
                }
                .environmentObject(adManager)
                .onAppear {
                    setupAds()
                }

                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
            }
        }
    }

    private func setupAds() {
        guard !isSetupDone else {
            return
        }
        
        MobileAds.shared.start { [weak adManager, weak rewardAd] status in
            guard let adManager = adManager,
                  let rewardAd = rewardAd else { return }
            
            rewardAd.setup(unitId: InterstitialAd.loadUnitId(name: "RewardAd") ?? "", interval: 60.0 * 60.0 * 24)
            adManager.setup()
            
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["8a00796a760e384800262e0b7c3d08fe"]

            // from AppDelegate didFinishLaunchingWithOptions()
            #if DEBUG
            adManager.prepare(interstitialUnit: .full, interval: 60.0)
            adManager.prepare(openingUnit: .launch, interval: 60.0)
            #else
            adManager.prepare(interstitialUnit: .full, interval: 60.0 * 60)
            adManager.prepare(openingUnit: .launch, interval: 60.0 * 5)
            #endif
            adManager.canShowFirstTime = true
        }
        
        isSetupDone = true
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            handleAppDidBecomeActive()
        case .inactive:
            // 앱이 비활성화될 때의 처리
            break
        case .background:
            // 앱이 백그라운드로 갈 때의 처리
            break
        @unknown default:
            break
        }
    }
    
    private func handleAppDidBecomeActive() {
        print("scene become active")
        Task{
            defer {
                LSDefaults.increaseLaunchCount()
            }
            
            let isTest = adManager.isTesting(unit: .launch)
            
            await adManager.show(unit: .launch)
        }
}