//
//  RNChapterInfo+RNExcelChapter.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

extension RNChapterInfo{
    func syncParts(_ chapter : RNExcelChapter, controller : RNModelController){
        for excelPart in chapter.parts{
            var modelPart = controller.findPart(excelPart.id);
            if modelPart == nil{
                modelPart = controller.createPart(no: excelPart.id, seq: excelPart.seq, name: excelPart.name);
                modelPart?.chapter = self;
                self.addToParts(modelPart!);
            }else{
                modelPart?.no = Int16(excelPart.id);
                modelPart?.name = excelPart.name;
            }
            
            modelPart?.content = excelPart.content;
        }
    }
}
