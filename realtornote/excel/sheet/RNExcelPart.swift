//
//  RNExcelPart.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class RNExcelPart : NSObject{
    class FieldNames{
        static let id = "id";
        static let seq = "seq";
        static let name = "name";
        static let chapter = "chapter";
        static let content = "content";
        static let content2 = "content2";
        static let content3 = "content3";
    }
    
    var id : Int = 0;
    var seq : Int = 0;
    var name : String = "";
    var chapter : Int = 0;
    var content : String = "";
    //var chapters
}
