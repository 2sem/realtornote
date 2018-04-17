//
//  RNSubjectInfo+.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

extension RNSubjectInfo{
    var subjectChapters : [RNChapterInfo]{
        get{
            return self.chapters?.allObjects as? [RNChapterInfo] ?? [];
        }
    }
}
