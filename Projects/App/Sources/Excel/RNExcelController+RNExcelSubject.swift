import Foundation
import CoreXLSX

extension RNExcelController{
    var subjectSheet : Worksheet!{
        get{
            try! self.document.parseWorksheet(at: workSheetPaths["subjects"]!)
        }
    }
    
    func loadSubjects(_ expand : Bool = false) -> [RNExcelSubject]{
        print("[start] load subjects");
        
        let sheet = self.subjectSheet!
        let headers = self.loadHeaders(from: sheet)
        var i = 1;
        var values : [RNExcelSubject] = [];
        
        var chapters : [RNExcelChapter] = [];
        
        if expand{
            chapters = self.loadChapters(expand);
        }
        
        while(true){
            let row = self.headerRow.advanced(by: i)
            let cells = self.loadCells(of: row, with: headers, in: sheet)
            
            guard let idCell = cells[RNExcelSubject.FieldNames.id] else {
                print("finish loading groups.");
                break
            }
            
            let nameCell = cells[RNExcelSubject.FieldNames.name]
            let detailCell = cells[RNExcelSubject.FieldNames.detail]
            
            let subject = RNExcelSubject();
            let id = idCell.stringValue(self.sharedStrings) ?? ""
            
            guard !id.isEmpty else{
                print("finish loading groups.");
                break;
            }
            
            let name = nameCell?.stringValue(self.sharedStrings) ?? ""
            let detail = detailCell?.stringValue(self.sharedStrings) ?? ""
            
            subject.id = Int(Double(id) ?? 0);
            subject.name = name;
            subject.detail = detail;
            
            print("add new subject. id[\(subject.id)] name[\(subject.name)]");
            values.append(subject);
            
            if expand{
                chapters.filter({ (chapter) -> Bool in
                    return chapter.subject == subject.id;
                }).forEach({ (chapter) in
                    subject.chapters.append(chapter);
                    chapters.remove(at: chapters.firstIndex(of: chapter)!);
                })
            }
            
            i += 1;
        }
        
        print("[end] load subjects");
        return values;
    }
}
