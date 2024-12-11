//
//  RNExcelChapter.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class RNExcelChapter : NSObject{
    class FieldNames{
        static let id = "id";
        static let seq = "seq";
        static let name = "name";
        static let subject = "subject";
    }
    
    var id : Int = 0;
    var seq : Int = 0;
    var name : String = "";
    var subject : Int = 0;
    var parts : [RNExcelPart] = [];
}
