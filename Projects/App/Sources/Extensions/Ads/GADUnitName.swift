//
//  GADUnitName.swift
//  App
//
//  Created by 영준 이 on 1/5/26.
//

extension SwiftUIAdManager {
    enum GADUnitName: String {
        case full = "FullAd"
        case reward = "QuizReward"
        case native = "FavoriteNative"
        case launch = "AppLaunch"
    }
    
#if DEBUG
    var testUnits: [GADUnitName] {
        [
            .full,
            .reward,
            .native,
            .launch,
        ]
    }
#else
    var testUnits: [GADUnitName] { [] }
#endif
    
}
