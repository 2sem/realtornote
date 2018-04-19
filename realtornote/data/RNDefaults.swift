//
//  RNDefaults.swift
//  democracyaction
//
//  Created by 영준 이 on 2017. 6. 18..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import UIKit

class RNDefaults{
    static var Defaults : UserDefaults{
        get{
            return UserDefaults.standard;
        }
    }
    
    class Keys{
        static let LastFullADShown = "LastFullADShown";
        static let LastShareShown = "LastShareShown";
        static let LastRewardADShown = "LastRewardADShown";
        
        static let LastNotice = "LastNotice";
        static let DataVersion = "DataVersion";
        
        static let ContentSize = "ContentSize";
        
        static let LastSubject = "LastSubject";
        static let LastChapter = "LastChapter";
        static let LastPart = "LastPart";
        static let LastContentOffset = "LastContentOffset";
    }
    
    static var LastFullADShown : Date{
        get{
            var seconds = Defaults.double(forKey: Keys.LastFullADShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastFullADShown);
        }
    }
    
    static var LastShareShown : Date{
        get{
            var seconds = Defaults.double(forKey: Keys.LastShareShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastShareShown);
        }
    }
    
    static var LastNotice : Date{
        get{
            var seconds = Defaults.double(forKey: Keys.LastNotice);
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
            return Defaults.float(forKey: Keys.ContentSize) ?? 0.0;
        }
        
        set(value){
            Defaults.set(value, forKey: Keys.ContentSize);
        }
    }
    
    static var LastSubject : Int{
        get{
            //UIApplication.shared.version
            return Defaults.integer(forKey: Keys.LastSubject) ?? 0;
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
        var lastChapters = RNDefaults.LastChapter;
        lastChapters[subject.description] = value;
        RNDefaults.LastChapter = lastChapters;
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
        var lastParts = RNDefaults.LastPart;
        lastParts[chapter.description] = value;
        RNDefaults.LastPart = lastParts;
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
        return RNDefaults.LastContentOffset[part.description] ?? 0.0;
    }
    
    static func setLastContentOffSet(part: Int, value : Float){
        var lastOffsets = RNDefaults.LastContentOffset;
        lastOffsets[part.description] = value;
        RNDefaults.LastContentOffset = lastOffsets;
    }
    
    static var LastRewardADShown : Date{
        get{
            var seconds = Defaults.double(forKey: Keys.LastRewardADShown);
            return Date.init(timeIntervalSince1970: seconds);
        }
        
        set(value){
            Defaults.set(value.timeIntervalSince1970, forKey: Keys.LastRewardADShown);
        }
    }
}
