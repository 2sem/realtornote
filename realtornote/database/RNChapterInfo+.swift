//
//  RNChapterInfo+.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

extension RNChapterInfo{
    var chapterParts : [RNPartInfo]{
        get{
            return self.parts?.allObjects as? [RNPartInfo] ?? [];
        }
    }
}
