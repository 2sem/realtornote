//
//  RNSubjectInfo+RNExcelSubject.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

extension RNSubjectInfo{
    func syncChapters(_ subject : RNExcelSubject, controller : RNModelController){
        for excelChapter in subject.chapters{
            var modelChapter = controller.findChapter(excelChapter.id);
            if modelChapter == nil{
                modelChapter = controller.createChapter(no: excelChapter.id, seq: excelChapter.seq, name: excelChapter.name);
                modelChapter?.subject = self;
                self.addToChapters(modelChapter!);
            }else{
                modelChapter?.no = Int16(excelChapter.id);
                modelChapter?.name = excelChapter.name;
            }
            
            modelChapter?.syncParts(excelChapter, controller: controller);
        }
    }
}
