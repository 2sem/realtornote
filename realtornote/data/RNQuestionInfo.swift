//
//  RNQuestionInfo.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 8. 14..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation

class RNQuestionInfo : NSObject{
    enum QuestionType{
        case inputAnswer
        case multipleChoice_child
        case multipleChoice_parent
        case OX
    }
    
    var questionType = QuestionType.multipleChoice_child;
    var positive = true;
    var reference : LSDocumentRecognizer.LSDocumentParagraph?;
    
    var answers : [RNQuestionAnswerInfo] = [];
    
    var title : String{
        get{
            var value = ""
            
            switch self.questionType {
                case .multipleChoice_child:
                    value = "다음에 대한 설명 또는 속하는 것으로 알맞은 것을 고르시오";
                    break;
                case .multipleChoice_parent:
                    value = "다음을 포함하거나 설명하는 것을 고르시오";
                    break;
                default:
                    break;
            }
            
            return value;
        }
    }
    var text : String{
        get{
            var value = "";
            
            switch self.questionType{
                case .multipleChoice_child:
                    var paragraph : LSDocumentRecognizer.LSDocumentParagraph! = self.reference;
                    //?.parent
                    
                    while(paragraph != nil){
                        value = "\(paragraph.text)" + (value.isEmpty ? "" : " > ") + value;
                        paragraph = paragraph?.parent;
                    }
                    
                    
                    break;
                default:
                    break
            }
            
            return value;
        }
    }
    
    static func createQuestions(_ paragraphs : [LSDocumentRecognizer.LSDocumentParagraph], count: Int = 10) -> [RNQuestionInfo]{
        var values : [RNQuestionInfo] = [];
        
        (1...count).forEach { (i) in
            values.append(self.createQuestion(paragraphs, type: RNQuestionInfo.QuestionType.multipleChoice_child));
        }
        
        return values;
    }
    
    static func createQuestion(_ paragraphs : [LSDocumentRecognizer.LSDocumentParagraph], type: QuestionType) -> RNQuestionInfo{
        //get paragraphs to create question
        var candidates = paragraphs.filter { (p) -> Bool in
            return !p.children.isEmpty && !p.root;
        }
        
        var value = RNQuestionInfo();
        
        switch type{
            case .multipleChoice_child:
                value.reference = candidates.random;
                //except question paragraph from answer candidates
                candidates.remove(value.reference!) { (left, right) -> Bool in
                    return left === right;
                }
                
                var answer = RNQuestionAnswerInfo();
                answer.title = value.reference?.children.random?.text ?? "";
                value.answers.append(answer);
                answer.isCorrect = true;
                
                //answer = paragraph parent of which is not same to question
                candidates = candidates.filter { (paragraph) -> Bool in
                    return !value.reference!.parent!.children.contains(paragraph);
                }
                
                //get 4 incorrect answers
                for i in 1...4{
                    var paragraph = candidates.random;
                    var answer = RNQuestionAnswerInfo();
                    answer.title = paragraph?.text ?? "";
                    
                    value.answers.append(answer);
                    if value.answers.count >= 5{
                        break;
                    }
                    
                    candidates.remove(paragraph!) { (left, right) -> Bool in
                        return left === right;
                    }
                }
                break;
            default:
                break;
        }
        
        value.answers.suffled { (left, right) -> Bool in
            return left === right;
        }
                
        return value;
    }
}
