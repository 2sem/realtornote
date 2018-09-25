//
//  RNExcelController+RNExcelChapter.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import XlsxReaderWriter

extension RNExcelController{
    var chapterSheet : BRAWorksheet?{
        get{
            return self.document?.workbook.worksheetNamed("chapters");
        }
    }
    
    func getChapterCell(columns : [String : String], column : String?, line : Int) -> BRACell?{
        guard columns[column ?? ""] != nil else{
            return nil;
        }
        
        return self.chapterSheet?.cell(forCellReference: "\(columns[column ?? ""] ?? "")\(line)");
    }
    
    func loadChapters(_ expand : Bool = false) -> [RNExcelChapter]{
        var values : [RNExcelChapter] = [];
        var i = 3;
        //var map : [String : RNExcelChapter] = [:];
        let columnLine = 2;
        let firstColumn = "B";
        //let firstRow = 3;
        
        let columns : [String : String] = self.loadColumns(sheet: self.chapterSheet!, line: columnLine, beginCell: firstColumn);
        
        var parts : [RNExcelPart] = [];

        print("[start] load chapters");
        
        if expand{
            parts = self.loadParts(expand);
        }
        
        while(true){
            let chapter = RNExcelChapter();
            let id = self.getChapterCell(columns: columns, column: RNExcelChapter.FieldNames.id, line: i)?.value ?? "";
            
            guard !id.isEmpty else{
                print("finish loading groups.");
                break;
            }
            
            chapter.id = Int(id) ?? 0;
            let seq = self.getChapterCell(columns: columns, column: RNExcelChapter.FieldNames.seq, line: i)?.value ?? "";
            let name = self.getChapterCell(columns: columns, column: RNExcelChapter.FieldNames.name, line: i)?.stringValue() ?? "";
            let subject = self.getChapterCell(columns: columns, column: RNExcelChapter.FieldNames.subject, line: i)?.value ?? "";
            
            chapter.name = name;
            chapter.seq = Int(seq) ?? 0;
            chapter.subject = Int(subject) ?? 0;
            
            print("add new chapter. id[\(chapter.id)] seq[\(chapter.seq)] subject[\(chapter.subject)] name[\(chapter.name)]");
            values.append(chapter);
            
            if expand{
                if expand{
                    parts.filter({ (part) -> Bool in
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
