import Foundation
import XlsxReaderWriter

extension RNExcelController{
    var subjectSheet : BRAWorksheet?{
        get{
            return self.document?.workbook.worksheetNamed("subjects");
        }
    }
    
    func getSubjectCell(columns : [String : String], column : String?, line : Int) -> BRACell?{
        guard columns[column ?? ""] != nil else{
            return nil;
        }
        
        return self.subjectSheet?.cell(forCellReference: "\(columns[column ?? ""] ?? "")\(line)");
    }
    
    func loadSubjects(_ expand : Bool = false) -> [RNExcelSubject]{
        var values : [RNExcelSubject] = [];
        var i = 3;
        //var map : [String : RNExcelSubject] = [:];
        let columnLine = 2;
        let firstColumn = "B";
        //let firstRow = 3;
        
        let columns : [String : String] = self.loadColumns(sheet: self.subjectSheet!, line: columnLine, beginCell: firstColumn);
        
        var chapters : [RNExcelChapter] = [];
        
        print("[start] load subjects");
        
        if expand{
            chapters = self.loadChapters(expand);
        }
        
        while(true){
            let subject = RNExcelSubject();
            let id = self.getSubjectCell(columns: columns, column: RNExcelSubject.FieldNames.id, line: i)?.value ?? "";
            
            guard !id.isEmpty else{
                print("finish loading groups.");
                break;
            }
            
            subject.id = Int(Double(id) ?? 0);
            let name = self.getSubjectCell(columns: columns, column: RNExcelSubject.FieldNames.name, line: i)?.stringValue() ?? "";
            let detail = self.getSubjectCell(columns: columns, column: RNExcelSubject.FieldNames.detail, line: i)?.stringValue() ?? "";
            
            subject.name = name;
            subject.detail = detail;
            
            print("add new subject. id[\(subject.id)] name[\(subject.name)]");
            values.append(subject);
            
            if expand{
                chapters.filter({ (chapter) -> Bool in
                    return chapter.subject == subject.id;
                }).forEach({ (chapter) in
                    subject.chapters.append(chapter);
                    chapters.remove(at: chapters.index(of: chapter)!);
                })
            }
            
            i += 1;
        }
        
        print("[end] load subjects");
        return values;
    }
}
