
import Foundation
//set XMLDictionary/XMLDictionary.h of target membership for XlsxReaderWriter to public
import CoreXLSX
import LSExtensions

class RNExcelController : NSObject{
    var document : XLSXFile!;
    var workbook : Workbook!;
    var workSheetPaths: [String : String] = [:]
    var sharedStrings: SharedStrings!
    let headerRow: UInt = 2
    var infoSheet : Worksheet!{
        get{
            try! self.document.parseWorksheet(at: workSheetPaths["info"]!)
        }
    }
    
    var version : String{
        get{
            let cells = self.infoSheet.cells(atRows: [2])
            let cell = cells.last
            let value = cell?.stringValue(self.sharedStrings) ?? ""
            
            return value
        }
    }
    
    var notice : String{
        get{
            let cell = self.infoSheet.cells(atRows: [3]).last
            return cell?.stringValue(self.sharedStrings) ?? ""
        }
    }
    
    var noticeDate : Date{
        get{
            let cell = self.infoSheet.cells(atRows: [4]).last
            return (cell?.stringValue(self.sharedStrings) ?? "").toDate("MM/dd/yy")!;
        }
    }
    
    var patch : String{
        get{
            let cell = self.infoSheet.cells(atRows: [5]).last
            return cell?.stringValue(self.sharedStrings) ?? "";
        }
    }
    
    var needToUpdate : Bool{
        get{
            let value = LSDefaults.DataVersion.compare(self.version, options: .numeric);
            let candidates : [ComparisonResult] = [.orderedAscending];
            
            return candidates.contains(value);
        }
    }
    
    static let Default = RNExcelController();
    
    override init(){
        super.init();
        
        guard let excelUrl = Bundle.main.url(forResource: "realtornote", withExtension: "xlsx") else{
            fatalError("Can not find Excel File");
        }
        
        print("excel : \(excelUrl)");
        if #available(iOS 16.0, *) {
            self.document = .init(filepath: excelUrl.path(percentEncoded: false))
        } else {
            self.document = .init(filepath: excelUrl.path)
        }
        
        self.workbook = try! document.parseWorkbooks().first
        self.workSheetPaths = try! document.parseWorksheetPathsAndNames(workbook: workbook)
            .reduce(into: [String : String](), { dict, sheetPath in
                        dict[sheetPath.name ?? ""] = sheetPath.path
                    })
        self.sharedStrings = try! document.parseSharedStrings()
    }
    
    var subjects : [RNExcelSubject] = [];
    func loadFromFlie(){
        self.subjects = self.loadSubjects(true);
    }
    
    static let headerCellLine = 2;
    static let beginCellColumn = "B";

    static let beginCell = Character("A");
    var eventCells : [String : String] = [:];
    
    public func loadHeaders(from sheet: Worksheet) -> [String : String] {
        guard let sharedStrings else {
            return [:]
        }
        
        return sheet.cells(atRows: [self.headerRow])
            .reduce(into: [String : String]()) { dict, cell in
                let columnId = cell.reference.column.value
                let cellValue = cell.stringValue(sharedStrings) ?? ""
                dict[columnId] = cellValue
            }
    }

    public func loadCells(of row: UInt, with headers: [String :  String], in sheet: Worksheet) -> [String : Cell] {
        return sheet.cells(atRows: [row])
            .reduce(into: [String : Cell]()) { dict, cell in
                let columnId = cell.reference.column.value
                guard let column = headers[columnId] else {
                    return
                }
                
                dict[column] = cell
            }
    }
}

