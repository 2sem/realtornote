//
//  GADRewardManager.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 9. 5..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import GoogleMobileAds
import LSExtensions
import FirebaseAnalytics

protocol GADRewardManagerDelegate : NSObjectProtocol{
    func GADRewardGetLastShowTime() -> Date;
    func GADRewardUpdate(showTime : Date);
    func GADRewardWillLoad();
    func GADRewardUserCompleted();
}

extension GADRewardManagerDelegate{
    func GADRewardWillLoad(){}
    func GADRewardUserCompleted(){}
}

class GADRewardManager : NSObject{
    var window : UIWindow;
    var unitId : String;
    var interval : TimeInterval = 60.0 * 60.0 * 3.0;
    var canShowFirstTime = true;
    var delegate : GADRewardManagerDelegate?;
    var rewarded = false;
    
    fileprivate static var _shared : GADRewardManager?;
    static var shared : GADRewardManager?{
        get{
            return _shared;
        }
    }
    
    init(_ window : UIWindow, unitId : String, interval : TimeInterval = 60.0 * 60.0 * 3.0) {
        self.window = window;
        self.unitId = unitId;
        self.interval = interval;
        
        super.init();
        //self.reset();
        if GADRewardManager._shared == nil{
            GADRewardManager._shared = self;
        }
    }
    
    func reset(){
        //RSDefaults.LastFullADShown = Date();
        self.delegate?.GADRewardUpdate(showTime: Date());
    }
    
    var rewardAd : RewardedInterstitialAd?;
    var canShow : Bool{
        get{
            var value = true;
            let now = Date();
            
            guard self.delegate != nil else {
                return value;
            }
            
            let lastShowTime = self.delegate!.GADRewardGetLastShowTime();
            let time_1970 = Date.init(timeIntervalSince1970: 0);
            
            //(!self.canShowFirstTime &&
            guard self.canShowFirstTime || lastShowTime > time_1970 else{
                if lastShowTime <= time_1970{
                    self.delegate?.GADRewardUpdate(showTime: now);
                }
                value = false;
                return value;
            }
            
            let spent = now.timeIntervalSince(lastShowTime);
            value = spent > self.interval;
            print("time spent \(spent) since \(lastShowTime). now[\(now)]");
            
            return value;
        }
    }
    
    func show(_ force : Bool = false){
        guard self.canShow || force else {
            //self.window.rootViewController?.showAlert(title: "알림", msg: "1시간에 한번만 후원하실 수 있습니다 ^^;", actions: [UIAlertAction(title: "확인", style: .default, handler: nil)], style: .alert);
            return;
        }
        
        self.prepare { [weak self](error) in
            if let _ = error {
                self?.showNoAds()
                return
            }
            
            guard (self?.rewardAd?.isReady() ?? false) else {
                self?.showNoAds()
                return
            }
            
            self?.__show()
        }
    }
    
    func prepare(_ completion: ((Error?) -> Void)? = nil){
        /*guard self.canShow else {
         return;
         }*/
        
        guard !(self.rewardAd?.isReady() ?? false) else{
            print("reward ad is already ready - self.rewardAd?.isReady");
            self.__show();
            return;
        }
        
        print("create new reward ad");
        let req = Request();
        
#if DEBUG
        //        let unitId = self.unitId;
        let unitId = "ca-app-pub-3940256099942544/6978759866"
#else
        let unitId = self.unitId;
#endif
        
        self.delegate?.GADRewardWillLoad();
        print("load rewarded ad[\(unitId)]");
        RewardedInterstitialAd.load(with: unitId, request: req) { [weak self](newAd, error) in
            if let error = error {
                print("rewarded ad load failed. error[\(error)]");
                completion?(error)
                return
            }
            
            print("rewarded ad loaded");
//            completion?(nil)
//            return
            self?.rewardAd = newAd;
            self?.rewardAd?.fullScreenContentDelegate = self;
            completion?(nil)
        }
    }
    
    private func __show(){
        guard self.window.rootViewController != nil else{
            return;
        }
        
        /*guard self.canShow else {
         return;
         }*/
        
        //ignore if alert is being presented
        /*if let alert = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? UIAlertController{
         alert.dismiss(animated: false, completion: nil);
         }*/
        
        guard !(UIApplication.shared.keyWindow?.rootViewController?.presentedViewController is UIAlertController) else{
            //alert.dismiss(animated: false, completion: nil);
            self.rewardAd = nil;
            return;
        }
        
        print("present full ad view[\(self.window.rootViewController?.description ?? "")]");
        self.rewarded = false;
        self.rewardAd?.present(from: self.window.rootViewController!, userDidEarnRewardHandler: { [weak self] in
            if let reward = self?.rewardAd?.adReward{
                print("user reward. type[\(reward.type)] amount[\(reward.amount)]");
            }
            self?.rewarded = true;
        })
        self.delegate?.GADRewardUpdate(showTime: Date());
        //RSDefaults.LastFullADShown = Date();
    }
    
    private func showNoAds(){
        self.window.rootViewController?.showAlert(title: "준비된 광고가 없습니다.", msg: "관심 가져주셔서 감사합니다.\n현재 준비된 광고가 없습니다", actions: [UIAlertAction.init(title: "확인", style: .default, handler: { _ in
//            Analytics.logLeesamEvent(.donationCompleted, parameters: [:]);
        }), UIAlertAction.init(title: "평가하기", style: .default, handler: { (act) in
            Analytics.logLeesamEvent(.reviewAfterDonation, parameters: [:]);
            UIApplication.shared.openReview();
        })], style: .alert);
    }
}

extension GADRewardManager : FullScreenContentDelegate{
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("reward has been compleated");
        
        self.rewardAd = nil;
        
        guard self.rewarded else{
            return;
        }
    
        Analytics.logLeesamEvent(.donationCompleted, parameters: [:]);
        
        self.window.rootViewController?.showAlert(title: "후원해주셔서 감사합니다.", msg: "불편하신 사항은 리뷰에 남겨주시면 반영하겠습니다.", actions: [UIAlertAction.init(title: "확인", style: .default, handler: { _ in
//            Analytics.logLeesamEvent(.donationCompleted, parameters: [:]);
        }), UIAlertAction.init(title: "평가하기", style: .default, handler: { (act) in
            Analytics.logLeesamEvent(.reviewAfterDonation, parameters: [:]);
            UIApplication.shared.openReview();
        })], style: .alert);
        self.delegate?.GADRewardUserCompleted();
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("reward fail[\(error)]");
    }
}
