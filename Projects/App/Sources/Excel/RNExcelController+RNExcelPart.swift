//
//  RNExcelController+RNExcelPart.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreXLSX

extension RNExcelController{
    var partSheet : Worksheet!{
        get{
            try! self.document.parseWorksheet(at: workSheetPaths["parts"]!)
        }
    }
    
    func loadParts(_ expand : Bool = false) -> [RNExcelPart]{
        print("[start] load parts");
        let sheet = self.partSheet!
        let headers = self.loadHeaders(from: sheet)
        var i = 1;
        var values : [RNExcelPart] = [];
        
        if expand{
            
        }
        
        while(true){
            let row = self.headerRow.advanced(by: i)
            let cells = self.loadCells(of: row, with: headers, in: sheet)
            
            guard let idCell = cells[RNExcelPart.FieldNames.id] else {
                break
            }
            
            let seqCell = cells[RNExcelPart.FieldNames.seq]
            let nameCell = cells[RNExcelPart.FieldNames.name]
            let chapterCell = cells[RNExcelPart.FieldNames.chapter]
            let contentCell = cells[RNExcelPart.FieldNames.content]
            
            let part = RNExcelPart();
            let id = idCell.stringValue(self.sharedStrings) ?? ""
            
            guard !id.isEmpty else{
                print("finish loading groups.");
                break;
            }
            
            let seq = seqCell?.stringValue(self.sharedStrings) ?? ""
            let name = nameCell?.stringValue(self.sharedStrings) ?? ""
            let chapter = chapterCell?.stringValue(self.sharedStrings) ?? ""
            let content = contentCell?.stringValue(self.sharedStrings) ?? ""
            let content2 = contentCell?.stringValue(self.sharedStrings) ?? ""
            let content3 = contentCell?.stringValue(self.sharedStrings) ?? ""
            
            part.id = Int(Double(id) ?? 0);
            part.name = name;
            part.seq = Int(Double(seq) ?? 0);
            part.chapter = Int(Double(chapter) ?? 0);
            part.content = content + content2 + content3;
            
            print("add new part. id[\(part.id)] seq[\(part.seq)] chapter[\(part.chapter)] name[\(part.name)]");
            values.append(part);
            
            if expand{
                
            }
            
            i += 1;
        }
        
        print("[end] load parts");
        return values;
    }
}
