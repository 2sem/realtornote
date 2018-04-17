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
        
        var root : Bool{
            get{
                return self.parent == nil;
            }
        }
        
        var indexType : IndexType = .dash;
        enum IndexType : String{
            case none = ""
            case number = "\\d+\\."
            case brackets_number = "\\(\\d+\\)"
            case dash = "-"
            case half_bracket_number = "\\d+\\)"
            case half_bracket_alpha = "\\S\\)"
            case term = "◎"
            case next = "⇒"
            
            var orderable : Bool{
                var values : [LSDocumentParagraph.IndexType]
                    = [.half_bracket_number, .brackets_number, .half_bracket_alpha];
                
                return values.contains(self);
            }
            
            func parseMatched(_ string: String) -> String?{
                return string.parse("^(?<index>\(self.rawValue))\\s*(?<text>[\\S\\s]+)$")[2];
            }
            
            func isMatched(string : String) -> Bool{
                return string.validate("^(?<index>\(self.rawValue))\\s*(?<text>[\\S\\s]+)$");
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
                        value = "\(index))";
                        break;
                    default:
                        break;
                }
                
                return value;
            }
            
            static func parseType(_ string: String) -> (IndexType, String){
                var value = [IndexType.number, .brackets_number, .dash, .half_bracket_number, .half_bracket_alpha, .term, .next]
                    .map({ (indexType) -> (IndexType, String) in
                    var text = indexType.parseMatched(string);
                    
                    return (text != nil ? indexType : .none, text ?? "");
                }).filter({ (indexType, text) -> Bool in
                    return indexType != .none;
                }).first;
                
                if value == nil{
                    value = (.none, string);
                }
                
                return value!;
            }
        }
        
        init(_ string : String) {
            let parse = IndexType.parseType(string.trimmingCharacters(in: CharacterSet.whitespaces));
            self.indexType = parse.0 ?? .none;
            self.text = parse.1;
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
                }else{
                    if let sibil = before.findParent(paragraph.indexType){
                        /*if !paragraph.indexType.orderable{
                            
                        }*/
                        sibil.parent?.children.append(paragraph);
                        paragraph.parent = sibil.parent;
                        paragraph.index = sibil.index + 1;
                    }else if paragraph.indexType == .term && before.indexType != .term
                        && before.parent != nil{
                        before.parent?.children.append(paragraph);
                        paragraph.parent = before.parent;
                        paragraph.index = before.index;
                    }else{
                        before.children.append(paragraph);
                        paragraph.parent = before;
                    }
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
