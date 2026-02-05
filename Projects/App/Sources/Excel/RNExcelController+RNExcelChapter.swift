//
//  RNExcelController+RNExcelChapter.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreXLSX

extension RNExcelController{
    var chapterSheet : Worksheet!{
        get{
            try! self.document.parseWorksheet(at: workSheetPaths["chapters"]!)
        }
    }
    
    func loadChapters(_ expand : Bool = false) -> [RNExcelChapter]{
        print("[start] load chapters");
        let sheet = self.chapterSheet!
        let headers = self.loadHeaders(from: sheet)
        var i = 1;
        //var map : [String : RNExcelChapter] = [:];
        let _ = 2;
        let firstColumn = "B";
        //let firstRow = 3;
                
        var parts : [RNExcelPart] = [];
        var values : [RNExcelChapter] = [];
        
        if expand{
            parts = self.loadParts(expand);
        }
        
        while(true){
            let row = self.headerRow.advanced(by: i)
            let cells = self.loadCells(of: row, with: headers, in: sheet)
            
            guard let idCell = cells[RNExcelChapter.FieldNames.id] else {
                break
            }
            
            let seqCell = cells[RNExcelChapter.FieldNames.seq]
            let nameCell = cells[RNExcelChapter.FieldNames.name]
            let subjectCell = cells[RNExcelChapter.FieldNames.subject]
            
            let chapter = RNExcelChapter();
            let id = idCell.stringValue(self.sharedStrings) ?? ""
            
            guard !id.isEmpty else{
                print("finish loading groups.");
                break;
            }
            
            let seq = seqCell?.stringValue(self.sharedStrings) ?? ""
            let name = nameCell?.stringValue(self.sharedStrings) ?? ""
            let subject = subjectCell?.stringValue(self.sharedStrings) ?? ""
            
            chapter.id = Int(Double(id) ?? 0);
            chapter.name = name;
            chapter.seq = Int(Double(seq) ?? 0);
            chapter.subject = Int(Double(subject) ?? 0);
            
            print("add new chapter. id[\(chapter.id)] seq[\(chapter.seq)] subject[\(chapter.subject)] name[\(chapter.name)]");
            values.append(chapter);
            
            if expand{
                if expand{
                    parts.filter({ (part) -> Bool in
                        debugPrint("parts.filter part.chapter[\(part.chapter)] chapter.id[\(chapter.id)]")
                        return part.chapter == chapter.id;
                    }).forEach({ (part) in
                        chapter.parts.append(part);
                        parts.remove(at: parts.index(of: part)!);
                    })
                }
            }
            
            i += 1;
        }
        
        print("[end] load chapters");
        return values;
    }
}
