//
//  SwiftUIAdManager.swift
//  App
//
//  Created by 영준 이 on 1/5/26.
//

import UIKit
import GADManager
import GoogleMobileAds
import AppTrackingTransparency

// MARK: - SwiftUI Ad Manager
class SwiftUIAdManager: NSObject, ObservableObject {
    private var gadManager: GADManager<GADUnitName>!
    var canShowFirstTime = true
    
    // 싱글톤 패턴으로 전역 접근 지원
    static var shared: SwiftUIAdManager?
    @Published var isReady: Bool = false
    
    func setup() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let adManager = GADManager<GADUnitName>(window)
        self.gadManager = adManager
        adManager.delegate = self
        
        // 싱글톤 인스턴스 설정
        SwiftUIAdManager.shared = self
        self.isReady = true
    }
    
    func prepare(interstitialUnit unit: GADUnitName, interval: TimeInterval) {
        gadManager?.prepare(interstitialUnit: unit, isTesting: self.isTesting(unit: unit), interval: interval)
    }
    
    func prepare(openingUnit unit: GADUnitName, interval: TimeInterval) {
        gadManager?.prepare(openingUnit: unit, isTesting: self.isTesting(unit: unit), interval: interval)
    }
    
    func prepare(rewardUnit unit: GADUnitName) {
        gadManager?.prepare(rewardUnit: unit, isTesting: self.isTesting(unit: unit))
    }
    
    /// Shows an ad for the specified unit.
    ///
    /// Note: This method may cause undo/transaction issues in SwiftUI.
    /// To avoid potential problems, consider using `showDeferred(unit:)` which defers the call to the main queue and ensures proper transaction handling.
    @MainActor
    @discardableResult
    func show(unit: GADUnitName) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let gadManager else {
                continuation.resume(returning: false)
                return
            }
            
            gadManager.show(unit: unit, isTesting: self.isTesting(unit: unit),
                            viewController: UIApplication.shared.keyRootViewController?.presentedViewController ) { unit, _,result  in
                continuation.resume(returning: result)
            }
        }
    }
    
    func createAdLoader(forUnit unit: GADUnitName, options: [NativeAdViewAdOptions] = []) -> AdLoader? {
        return gadManager?.createNativeLoader(forAd: unit, isTesting: self.isTesting(unit: unit))
    }
    
    // MARK: - Testing Flags
    func isTesting(unit: GADUnitName) -> Bool {
        return testUnits.contains(unit)
    }
    
    // 기존 코드 호환성을 위한 메서드
    func requestPermission(completion: @escaping (Bool) -> Void) {
        guard let gadManager else {
            completion(false)
            return
        }
        
        gadManager.requestPermission { status in
            completion(status == .authorized)
        }
    }
    
    // 앱 추적 권한 요청 (아직 결정되지 않은 경우에만)
    // gadManager 생성 전에도 동작해야 하므로 ATTrackingManager를 직접 호출한다.
    @MainActor
    @discardableResult
    func requestTrackingAuthorizationIfNeeded() async -> Bool {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            debugPrint(#function, "Already determined", ATTrackingManager.trackingAuthorizationStatus.rawValue)
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
        }
        
        let status = await ATTrackingManager.requestTrackingAuthorization()
        return status == .authorized
    }
}

extension SwiftUIAdManager: GADManagerDelegate {
    typealias E = GADUnitName
    
    func GAD<E>(manager: GADManager<E>, lastPreparedTimeForUnit unit: E) -> Date {
        return LSDefaults.LastOpeningAdPrepared
    }
    
    func GAD<E>(manager: GADManager<E>, updateLastPreparedTimeForUnit unit: E, preparedTime time: Date) {
        LSDefaults.LastOpeningAdPrepared = time
    }
    
    func GAD<E>(manager: GADManager<E>, lastShownTimeForUnit unit: E) -> Date {
        let now = Date()
        if LSDefaults.LastFullADShown > now {
            LSDefaults.LastFullADShown = now
        }
        return LSDefaults.LastFullADShown
    }
    
    func GAD<E>(manager: GADManager<E>, updatShownTimeForUnit unit: E, showTime time: Date) {
        LSDefaults.LastFullADShown = time
    }
}
