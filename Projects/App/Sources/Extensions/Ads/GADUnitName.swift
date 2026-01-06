//
//  GADUnitName.swift
//  App
//
//  Created by 영준 이 on 1/5/26.
//

extension SwiftUIAdManager {
    enum GADUnitName: String {
        case quizReward = "QuizReward"
        case favoriteNative = "FavoriteNative"
        case appLaunch = "AppLaunch"
    }
    
#if DEBUG
    var testUnits: [GADUnitName] {
        [
            .quizReward,
            .favoriteNative,
            .appLaunch,
        ]
    }
#else
    var testUnits: [GADUnitName] { [] }
#endif
    
}
