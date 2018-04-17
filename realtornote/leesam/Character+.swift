//
//  Character.swift
//  WhoCallMe
//
//  Created by 영준 이 on 2016. 3. 15..
//  Copyright © 2016년 leesam. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


extension Character {
    func isKorean() -> Bool{
        let code = self.scalars.first?.value;
        
        //complete || short
        return (code >= 0xAC00 && code <= 0xD7AF) || (code >= 0x3130 && code <= 0x318F);
    }
    
    static let koreanBegin = "가".unicodeScalars.first!.value;
    static let koreanSingleChoSeongs = ["ㄱ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ", "ㅅ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ" ];
    static let koreanChoSeongs = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ" ];
    static let koreanJungSeongs = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅕ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"];
    static let koreanJongSeongs = [" ", "ㄱ", "ㄲ", "ㄱㅅ", "ㄴ", "ㄴㅈ", "ㄴㅎ", "ㄷ", "ㄹ", "ㄹㄱ", "ㄹㅁ", "ㄹㅂ", "ㄹㅅ", "ㄹㅌ", "ㄹㅍ", "ㄹㅎ", "ㅁ", "ㅂ", "ㅂㅅ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"];
    
    func getKoreanIndex() -> UInt32?{
        var value : UInt32?;
        
        guard self.isKorean() else{
            return value;
        }
        
        let uCode = self.scalars.first!.value;
        
        guard uCode >= Character.koreanBegin else{
            return value;
        }
        
        value = uCode - Character.koreanBegin;
        
        return value;
    }
    
    var isKoreanPart : Bool{
        get{
            let uCode = self.scalars.first?.value;

            return uCode >= 0x3131 && uCode <= 0x318E;
        }
    }
    
    func getKoreanChoseong() -> String?{
        var value : String?;
        
        guard self.isKorean() else{
            return value;
        }
        
        //is not completed korean character?
        
        
        let uIndex = self.getKoreanIndex();
        
        if uIndex == nil{
            if isKoreanPart{
                value = String(self);
            }
            return value;
        }
        
        let idx_cho = uIndex! / UInt32(Character.koreanJungSeongs.count * Character.koreanJongSeongs.count);
        
        
        value = Character.koreanChoSeongs[Int(idx_cho)];
        
        return value;
    }
    
    func getKoreanJungSeong() -> String?{
        var value : String?;
        
        guard self.isKorean() else{
            return value;
        }
        
        let uIndex = self.getKoreanIndex()!;
        let idx_jung = (uIndex % UInt32(Character.koreanJungSeongs.count * Character.koreanJongSeongs.count)) / (UInt32(Character.koreanJongSeongs.count));
        
        value = Character.koreanJungSeongs[Int(idx_jung)];
        
        return value;
    }
    
    func getKoreanJongSeong() -> String?{
        var value : String?;
        
        guard self.isKorean() else{
            return value;
        }
        
        let uIndex = self.getKoreanIndex()!;
        let idx_jong = uIndex % UInt32(Character.koreanJungSeongs.count);
            
        value = Character.koreanJongSeongs[Int(idx_jong)];
        
        return value;
    }
    
    func getKoreanParts() -> String{
        var value : String = "";
        
        guard self.isKorean() else{
            return value;
        }
        
        //is not completed korean character?
        
        let uIndex : UInt32! = self.getKoreanIndex();
        
        if uIndex == nil{
            if isKoreanPart{
                value = String(self);
            }
            return value;
        }
        
        let idx_cho = Int(uIndex / UInt32(Character.koreanJungSeongs.count * Character.koreanJongSeongs.count));
        let idx_jung = Int((uIndex % UInt32(Character.koreanJungSeongs.count * Character.koreanJongSeongs.count)) / (UInt32(Character.koreanJongSeongs.count)));
        let idx_jong = Int(uIndex % UInt32(Character.koreanJongSeongs.count));
            //* Character.koreanJongSeongs.count));
        
        var cho = Character.koreanChoSeongs.count > idx_cho ? Character.koreanChoSeongs[idx_cho] : "";
        var jung = Character.koreanJungSeongs.count > idx_jung ? Character.koreanJungSeongs[Int(idx_jung)] : "";
        var jong = Character.koreanJongSeongs.count > idx_jong ? Character.koreanJongSeongs[idx_jong] : "";
        
        //print("get kor char parts \(self) => cho[\(idx_cho)] jung[\(idx_jung)] jong[\(idx_jong)]");
        value = cho + jung + jong;
        
        return value;
    }
    
    func increase(_ num : UInt32) -> Character{
        var chrValue = UInt32(String(self).unicodeScalars.first!.value + num);
        return Character.init(UnicodeScalar(chrValue)!);
    }
    
    var scalars : String.UnicodeScalarView {
        get{
            var scalarString = String(self);
            let scalars = scalarString.unicodeScalars;
            
            return scalars;
        }
    }
}
