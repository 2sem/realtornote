//
//  GADRewardedInterstitialAd+.swift
//  realtornote
//
//  Created by 영준 이 on 2021/05/19.
//  Copyright © 2021 leesam. All rights reserved.
//

import Foundation
import GoogleMobileAds

extension RewardedInterstitialAd{
    func isReady(for viewController: UIViewController? = nil) -> Bool{
        do{
            let rootViewController = viewController ?? UIApplication.shared.firstKeyWindow?.rootViewController
            if let viewController = rootViewController{
                try self.canPresent(from: viewController);
                return true;
            }
            return false
        }catch{}
        
        return false;
    }
}
