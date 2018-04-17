//
//  RNExcelController+RNExcelPart.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import XlsxReaderWriter

extension RNExcelController{
    var partSheet : BRAWorksheet?{
        get{
            return self.document?.workbook.worksheetNamed("parts");
        }
    }
    
    func getPartCell(columns : [String : String], column : String?, line : Int) -> BRACell?{
        guard columns[column ?? ""] != nil else{
            return nil;
        }
        
        return self.partSheet?.cell(forCellReference: "\(columns[column ?? ""] ?? "")\(line)");
    }
    
    func loadParts(_ expand : Bool = false) -> [RNExcelPart]{
        var values : [RNExcelPart] = [];
        var i = 3;
        var map : [String : RNExcelPart] = [:];
        let columnLine = 2;
        let firstColumn = "B";
        let firstRow = 3;
        
        var columns : [String : String] = self.loadColumns(sheet: self.partSheet!, line: columnLine, beginCell: firstColumn);
        
        //var parts : [RNExcelPart] = [];
        
        print("[start] load parts");
        
        if expand{
            
        }
        
        while(true){
            var part = RNExcelPart();
            var id = self.getPartCell(columns: columns, column: RNExcelPart.FieldNames.id, line: i)?.value ?? "";
            
            guard !(id ?? "").isEmpty else{
                print("finish loading groups.");
                break;
            }
            
            part.id = Int(id ?? "") ?? 0;
            var seq = self.getPartCell(columns: columns, column: RNExcelPart.FieldNames.seq, line: i)?.value ?? "";
            var name = self.getPartCell(columns: columns, column: RNExcelPart.FieldNames.name, line: i)?.stringValue() ?? "";
            var chapter = self.getPartCell(columns: columns, column: RNExcelPart.FieldNames.chapter, line: i)?.value ?? "";
            var content = self.getPartCell(columns: columns, column: RNExcelPart.FieldNames.content, line: i)?.stringValue() ?? "";
            
            part.name = name;
            part.seq = Int(seq ?? "") ?? 0;
            part.chapter = Int(chapter ?? "") ?? 0;
            part.content = content;
            
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
