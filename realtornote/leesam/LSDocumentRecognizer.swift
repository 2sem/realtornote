//
//  LSDocumentRecognizer.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 8. 8..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class LSDocumentRecognizer : NSObject{
    static let shared = LSDocumentRecognizer();
    
    public class LSDocumentParagraph : NSObject{
        var index : Int = 1;
        var text : String = "";
        var parent : LSDocumentParagraph?;
        var children : [LSDocumentParagraph] = [];
        var level : Int{
            get{
                return self.parent == nil ? 0 : (1 + self.parent!.level ?? 0);
            }
        }
        
        var isRoot : Bool{
            get{
                return self.parent == nil;
            }
        }
        
        var root : LSDocumentParagraph{
            get{
                return self.parent == nil ? self : self.parent!.root;
            }
        }
        
        var indexingParent : LSDocumentParagraph{
            get{
                return self.indexType.isIndexing ? self : self.parent!.indexingParent;
            }
        }
        
        var allParentHasSingleChild : Bool{
            get{
                return (self.parent?.children.count ?? 1) == 1 && (self.parent?.allParentHasSingleChild ?? true);
            }
        }
        
        func sibilsHasChild(_ type : IndexType? = nil) -> Bool{
            var value = false;
            
            guard self.parent != nil else{
                return value;
            }
            
            for sibil in self.parent!.children{
                guard sibil !== self else{
                    continue;
                }
                
                if type == nil{
                    value = value || sibil.children.any;
                }else{
                    value = value || sibil.children.filter({ (p) -> Bool in
                        return p.indexType == type;
                    }).any;
                }
            }
            
            return value;
        }
        
        var indexType : IndexType = .dash;
        enum IndexType : String{
            case none = ""
            case number = "(?<index>\\d+)\\."
            case brackets_number = "\\((?<index>\\d+)\\)"
            case dash = "-"
            case half_bracket_number = "(?<index>\\d+)\\)"
            case half_bracket_alpha = "(?<index>\\S)\\)"
            case term = "◎"
            case next = "⇒"
            
            var orderable : Bool{
                var values : [LSDocumentParagraph.IndexType]
                    = [.half_bracket_number, .brackets_number, .half_bracket_alpha];
                
                return values.contains(self);
            }
            
            var isIndexing : Bool{
                get{
                    //.half_bracket_alpha, 
                    return [.number, .brackets_number, .half_bracket_number].contains(self);
                }
            }
            
            func parseMatched(_ string: String) -> [Int : String]{
                return string.parse("^\(self.rawValue)\\s*(?<text>[\\S\\s]+)$");
            }
            
            func isMatched(string : String) -> Bool{
                return string.validate("^\(self.rawValue)\\s*(?<text>[\\S\\s]+)$");
            }
            
            func toIndexString(_ index : Int) -> String{
                var value = self.rawValue;
                
                switch(self){
                    case .number:
                        value = "\(index).";
                        break;
                    case .brackets_number:
                        value = "(\(index))";
                        break;
                    case .half_bracket_number:
                        value = "\(index))";
                        break;
                    case .half_bracket_alpha:
                        value = "\(index.alpha))";
                        break;
                    default:
                        break;
                }
                
                return value;
            }
            
            static func parseType(_ string: String) -> (IndexType, Int, String){
                var value = [IndexType.number, .brackets_number, .dash, .half_bracket_number, .half_bracket_alpha, .term, .next]
                    .map({ (indexType) -> (IndexType, Int, String) in
                    var matchResults = indexType.parseMatched(string);
                    var text = matchResults[matchResults.keys.max() ?? 0];
                    var index = 0;
                    
                    if matchResults.keys.count > 2{
                        index = Int(matchResults[1]!) ?? 0;
                        
                        if indexType == .half_bracket_alpha{
                            index = Int(alpha: matchResults[1]!);
                            if index == 0{
                                text = nil;
                            }
                        }
                    }
                    
                    return (text != nil ? indexType : .none, index, text ?? "");
                }).filter({ (indexType, index, text) -> Bool in
                    return indexType != .none;
                }).first;
                
                if value == nil{
                    value = (.none, 0, string);
                }
                
                return value!;
            }
        }
        
        init(_ string : String) {
            let parse = IndexType.parseType(string.trimmingCharacters(in: CharacterSet.whitespaces));
            self.indexType = parse.0 ?? .none;
            self.index = parse.1
            self.text = parse.2;
        }
        
        func findParent(_ type : IndexType) -> LSDocumentParagraph?{
            return self.parent?.indexType == type ? self.parent : self.parent?.findParent(type);
        }
        
        var allParagraphs : [LSDocumentParagraph]{
            get{
                var values : [LSDocumentParagraph] = [];
                
                for paragraph in self.children{
                    values.append(paragraph);
                    values.append(contentsOf: paragraph.allParagraphs);
                }
                
                return values;
            }
        }
    }
    
    //1. (1), -, 1), @
    func recognize(doc : String, symbols : [LSDocumentParagraph.IndexType] = [.number, .brackets_number, .half_bracket_number, .dash, .term, .next]) -> [LSDocumentParagraph]{
        var values : [LSDocumentParagraph] = [];
        
        var lines : [String] = doc.components(separatedBy: CharacterSet.newlines);
        
        var before : LSDocumentParagraph!;
        
        for line in lines{
            var string = line.trimmingCharacters(in: CharacterSet.whitespaces);
            guard !string.isEmpty else{
                continue;
            }
            
            var paragraph = LSDocumentParagraph(string);
            //print("doc recognize index[\(paragraph.indexType)] text[\(paragraph.text)]");
            
            //this paragraph is first paragraph
            if before != nil{
                //check if index level changed
                if before.indexType == paragraph.indexType{
                    paragraph.index = before.index + 1;
                    if before.parent != nil{
                        before.parent?.children.append(paragraph);
                        paragraph.parent = before.parent;
                    }
                }else if let sibil = before.findParent(paragraph.indexType){
                    if paragraph.index == 1{
                        before.children.append(paragraph);
                        paragraph.parent = before;
                        //paragraph.index = before.index;
                    }else{
                        sibil.parent?.children.append(paragraph);
                        paragraph.parent = sibil.parent;
                    }
                }/*else if paragraph.indexType == .term && before.indexType != .term
                        && before.parent != nil{
                     
                 }*/else if paragraph.indexType == .term{
                    var indexingParent = before.indexingParent;
                    
                    if let sibil = before.findParent(paragraph.indexType){
                        sibil.parent?.children.append(paragraph);
                        paragraph.parent = sibil.parent;
                    }
                    else if indexingParent != before || before.parent == nil{
                        indexingParent.children.append(paragraph);
                        paragraph.parent = indexingParent;
                    }else if (before.parent?.children ?? []).count > 1 && !before.sibilsHasChild() {
                        before.parent?.children.append(paragraph);
                        paragraph.parent = before.parent;
                    }else{
                        before.children.append(paragraph);
                        paragraph.parent = before;
                    }
                }else{
                    before.children.append(paragraph);
                    paragraph.parent = before;
                }
                /*else before.indexType <= paragraph.indexType{
                    
                }*/
            }
            
            if paragraph.parent == nil{
                values.append(paragraph);
            }
            
            before = paragraph;
        }
        
        return values;
    }
    
    func toString(_ paragraphs : [LSDocumentParagraph], space : String = " ") -> String{
        var values : [String] = [];
        
        for paragraph in paragraphs{
            //
            //+
            values.append(space.multiply(paragraph.level)
                + "\(paragraph.indexType.toIndexString(paragraph.index)) \(paragraph.text)"
                + (paragraph.children.isEmpty ? "" : "\n")
                + self.toString(paragraph.children, space: space))
        }
        
        //" ".multiply(3);
        
        /*paragraphs.map({ (p) -> String in
         return "\(p.indexType.toIndexString(p.index)) \(p.text)";
         }).joined(separator: "\n");*/
        
        return values.joined(separator: "\n");
    }
}
