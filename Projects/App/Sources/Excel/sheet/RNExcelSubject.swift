//
//  DAExcelGroupInfo.swift
//  democracyaction
//
//  Created by 영준 이 on 2017. 6. 8..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class RNExcelSubject : NSObject{
    class FieldNames{
        static let id = "id";
        static let name = "name";
        static let detail = "detail";
    }
    
    var id : Int = 0;
    var name : String = "";
    var detail : String = "";
    var chapters : [RNExcelChapter] = [];
}
