
import Foundation
//set XMLDictionary/XMLDictionary.h of target membership for XlsxReaderWriter to public
import XlsxReaderWriter

class RNExcelController : NSObject{
    var document : BRAOfficeDocumentPackage?;
    var infoSheet : BRAWorksheet?{
        get{
            return self.document?.workbook.worksheetNamed("info");
        }
    }
    
    var version : String{
        get{
            return self.infoSheet?.cell(forCellReference: "C2")?
                .stringValue() ?? "";
        }
    }
    
    var notice : String{
        get{
            return self.infoSheet?.cell(forCellReference: "C3")?
                .stringValue() ?? "";
        }
    }
    
    var noticeDate : Date{
        get{
            let cell = self.infoSheet?.cell(forCellReference: "C4");
            return (cell?.stringValue() ?? "").toDate("MM/dd/yy")!;
        }
    }
    
    var patch : String{
        get{
            let cell = self.infoSheet?.cell(forCellReference: "C5");
            
            return cell?.stringValue() ?? "";
        }
    }
    
    var needToUpdate : Bool{
        get{
            return LSDefaults.DataVersion < self.version;
        }
    }
    
    static let Default = RNExcelController();
    
    override init(){
        guard let excel_path = Bundle.main.url(forResource: "realtornote", withExtension: "xlsx") else{
            fatalError("Can not find Excel File");
        }
        print("excel : \(excel_path)");
        self.document = BRAOfficeDocumentPackage.open(excel_path.path);
        //        var cell = sheet?.cell(forCellReference: "A2");
        //        print("\(cell?.columnName()) - \(cell?.columnIndex()) => \(cell?.stringValue())");
    }
    
    var subjects : [RNExcelSubject] = [];
    func loadFromFlie(){
        self.subjects = self.loadSubjects(true);
        /*var groups = self.loadGroups();
         for group in groups{
         self.groups[group.id] = group;
         }*/
    }
    
    func getCell(sheet: BRAWorksheet?, column : String?, cells : [String : String], line : Int) -> BRACell?{
        guard cells[column ?? ""] != nil else{
            return nil;
        }
        
        return sheet?.cell(forCellReference: "\(cells[column ?? ""] ?? "")\(line)");
    }
    
    func loadColumns(sheet : BRAWorksheet, line : Int, beginCell : String) -> [String : String]{
        var values : [String : String] = [:];
        var i = 0;
        
        var ch = Character(beginCell).increase(UInt32(i));
        
        //.unicodeScalars.first!.value;
        
        while(true){
            ch = Character(beginCell).increase(UInt32(i));
            let cell = sheet.cell(forCellReference: "\(ch)\(line)");
            guard !(cell?.stringValue() ?? "").isEmpty else{
                break;
            }
            
            values[cell?.stringValue() ?? ""] = "\(ch)";
            i += 1;
        }
        
        return values;
    }
}

