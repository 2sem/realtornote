//
//  RNDefaults.swift
//  democracyaction
//
//  Created by 영준 이 on 2017. 6. 18..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import UIKit
import StringLogger

class LSDefaults{
    static var Defaults : UserDefaults{
        get{
            return UserDefaults.standard;
        }
    }
    
    class Keys{
        static let LastFullADShown = "LastFullADShown";
        static let LastShareShown = "LastShareShown";
        static let LastRewardADShown = "LastRewardADShown";
        static let LastOpeningAdPrepared = "LastOpeningAdPrepared";

        static let LastNotice = "LastNotice";
        static let DataVersion = "DataVersion";
        
        static let ContentSize = "ContentSize";
        
        static let LastSubject = "LastSubject";
        static let LastChapter = "LastChapter";
        static let LastPart = "LastPart";
        static let LastContentOffset = "LastContentOffset";
        
        static let LaunchCount = "LaunchCount";
        
        static let FavoriteSortType = "FavoriteSortType";
        
        static let alarmInitialized = "alarmInitialized";
        
        static let AdsShownCount = "AdsShownCount";
        static let AdsTrackingRequested = "AdsTrackingRequested";
    }
    
    static var LastFullADShown : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastFullADShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastFullADShown);
        }
    }
    
    static var LastShareShown : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastShareShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastShareShown);
        }
    }
    
    static var LastNotice : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastNotice);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastNotice);
        }
    }
    
    static var DataVersion : String{
        get{
            //UIApplication.shared.version
            return Defaults.string(forKey: Keys.DataVersion) ?? "0.0";
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.DataVersion);
        }
    }
    
    static var ContentSize : Float{
        get{
            //UIApplication.shared.version
            return Defaults.float(forKey: Keys.ContentSize);
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.ContentSize);
        }
    }
    
    static var LastSubject : Int{
        get{
            //UIApplication.shared.version
            return Defaults.integer(forKey: Keys.LastSubject);
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.LastSubject);
        }
    }
    
    static var LastChapter : [String : Int]{
        get{
            //UIApplication.shared.version
            return Defaults.dictionary(forKey: Keys.LastChapter) as? [String : Int] ?? [:];
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.LastChapter);
        }
    }
    
    static func setLastChapter(subject: Int, value : Int){
        var lastChapters = LSDefaults.LastChapter;
        lastChapters[subject.description] = value;
        LSDefaults.LastChapter = lastChapters;
    }
    
    static var LastPart : [String : Int]{
        get{
            //UIApplication.shared.version
            return Defaults.dictionary(forKey: Keys.LastPart) as? [String : Int] ?? [:];
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.LastPart);
        }
    }
    
    static func setLastPart(chapter: Int, value : Int){
        var lastParts = LSDefaults.LastPart;
        lastParts[chapter.description] = value;
        LSDefaults.LastPart = lastParts;
    }
    
    static var LastContentOffset : [String : Float]{
        get{
            //UIApplication.shared.version
            return Defaults.dictionary(forKey: Keys.LastContentOffset) as? [String : Float] ?? [:];
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.LastContentOffset);
        }
    }
    
    static func getLastContentOffset(_ part: Int) -> Float{
        return LSDefaults.LastContentOffset[part.description] ?? 0.0;
    }
    
    static func setLastContentOffSet(part: Int, value : Float){
        var lastOffsets = LSDefaults.LastContentOffset;
        lastOffsets[part.description] = value;
        LSDefaults.LastContentOffset = lastOffsets;
    }
    
    static var LastRewardADShown : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastRewardADShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastRewardADShown);
        }
    }
    
    static var LastOpeningAdPrepared : Date{
        get{
            let seconds = Defaults.double(forKey: Keys.LastOpeningAdPrepared);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastOpeningAdPrepared);
        }
    }
    
    static func increaseLaunchCount(){
        self.LaunchCount = self.LaunchCount.advanced(by: 1);
    }
    static var LaunchCount : Int{
        get{
            //UIApplication.shared.version
            return Defaults.integer(forKey: Keys.LaunchCount);
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.LaunchCount);
        }
    }
    
    static var isFirstLaunch: Bool { LaunchCount <= 1 }
    
    static var FavoriteSortType : Int{
        get{
            //UIApplication.shared.version
            return Defaults.integer(forKey: Keys.FavoriteSortType);
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.FavoriteSortType);
        }
    }
    
    static var alarmInitialized : Bool{
        get{
            //UIApplication.shared.version
            return Defaults.bool(forKey: Keys.alarmInitialized);
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.alarmInitialized);
        }
    }
    
    
    
    
}

extension LSDefaults{
    static var AdsShownCount : Int{
        get{
            return Defaults.integer(forKey: Keys.AdsShownCount);
        }
        
        set{
            Defaults.set(newValue, forKey: Keys.AdsShownCount);
        }
    }
    
    static func increateAdsShownCount(){
        guard AdsShownCount < 3 else {
            return
        }
        
        AdsShownCount += 1;
        "Ads Shown Count[\(AdsShownCount)]".debug();
    }
    
    static var AdsTrackingRequested : Bool{
        get{
            return Defaults.bool(forKey: Keys.AdsTrackingRequested);
        }
        
        set{
            Defaults.set(newValue, forKey: Keys.AdsTrackingRequested);
        }
    }
    
    static func requestAppTrackingIfNeed() -> Bool{
        guard !AdsTrackingRequested else{
            return false;
        }
        
        guard AdsShownCount >= 3 else{
            AdsShownCount += 1;
            return false;
        }
        
        guard #available(iOS 14.0, *) else{
            return false;
        }
        
        AppDelegate.sharedGADManager?.requestPermission(completion: { (result) in
            AdsTrackingRequested = true;
        })
        
        return true;
    }
}
