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
    var reference : LSDocumentRecognizer.LSDocumentParagraph!;
    
    var answers : [RNQuestionAnswerInfo] = [];
    
    var title : String{
        get{
            var value = ""
            
            switch self.questionType {
                case .multipleChoice_child:
                    if self.positive{
                        value = "다음에 대한 설명 또는 속하는 것으로 알맞은 것을 고르시오";
                    }else{
                        value = "다음에 대한 설명이 아니거나 속하지 않는 것을 고르시오";
                    }
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
                        value = "\(paragraph.text)" + (value.isEmpty ? "" : " 〉 ") + value;
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
        var remain = count;
        let paragraphs = paragraphs;
        
        (1...count/2).forEach { (i) in
            let q = self.createQuestion(paragraphs, type: RNQuestionInfo.QuestionType.multipleChoice_child, positive: true);
            guard q != nil && !values.contains(where: { (question) -> Bool in
                return question.reference === q!.reference;
            }) else{
                return;
            }
            
            values.append(q!);
            /*paragraphs.remove(q!.reference, where: { (left, right) -> Bool in
                return left === right;
            });*/
        }
        
        remain = count - values.count;
        (1...remain).forEach { (i) in
            let q = self.createQuestion(paragraphs, type: RNQuestionInfo.QuestionType.multipleChoice_child, positive: false);
            guard q != nil && !values.contains(where: { (question) -> Bool in
                return question.reference === q!.reference;
            }) else{
                return;
            }
            
            values.append(q!);
            /*paragraphs.remove(q!.reference, where: { (left, right) -> Bool in
                return left === right;
            });*/
        }
        
        return values.suffle(where: { (left, right) -> Bool in
            return left === right;
        });
    }
    
    static func createQuestion(_ paragraphs : [LSDocumentRecognizer.LSDocumentParagraph], type: QuestionType, positive : Bool = true) -> RNQuestionInfo?{
        //get paragraphs to create question
        var candidates = paragraphs.filter { (p) -> Bool in
            return p.children.any && !p.isRoot;
        }
        
        if candidates.count <= 5{
            candidates = paragraphs.filter { (p) -> Bool in
                return p.children.any && p.isRoot;
            }
        }
        
        let value : RNQuestionInfo! = RNQuestionInfo();
        value.positive = positive;
        
        switch type{
            case .multipleChoice_child:
                if positive{
                    value.reference = candidates.random;
                }else{
                    var childCount = 4;
                    
                    repeat{
                        value.reference = candidates.filter({ (c) -> Bool in
                            return c.children.count >= childCount;
                        }).random;
                        childCount = childCount - 1;
                    }while(value.reference == nil);
                }
                
                //except question paragraph from answer candidates
                candidates.remove(value.reference!) { (left, right) -> Bool in
                    return left === right;
                }
                
                let answer = RNQuestionAnswerInfo();
                value.answers.append(answer);
                answer.isCorrect = true;
                
                if positive{
                    guard candidates.count >= 4 else{
                        return nil;
                    }
                    
                    answer.title = value.reference?.children.random?.text ?? "";
                    
                    //answer = paragraph parent of which is not same to question
                    candidates = candidates.filter { (paragraph) -> Bool in
                        //.parent!
                        return !value.reference!.children.contains(paragraph);
                    }
                    
                    for _ in 1...4{
                        let paragraph = candidates.random;
                        let answer = RNQuestionAnswerInfo();
                        answer.title = paragraph?.text ?? "";
                        
                        value.answers.append(answer);
                        if value.answers.count >= 5{
                            break;
                        }
                        
                        candidates.remove(paragraph!) { (left, right) -> Bool in
                            return left === right;
                        }
                    }
                }else{
                    guard candidates.count >= 1 else{
                        return nil;
                    }
                    
                    for candidate in value.reference?.children.takeRandom(4) ?? []{
                        let answer = RNQuestionAnswerInfo();
                        answer.title = candidate.text ?? "";
                        
                        value.answers.append(answer);
                    }
                    
                    let incorrect = candidates.filter({ (paragraph) -> Bool in
                        return !paragraph.children.contains(value.reference!) && !value.reference!.children.contains(paragraph);
                    }).random;
                    
                    answer.title = incorrect?.children.random?.text ?? "";
                }
                
                //get 4 incorrect answers
                                break;
            case .multipleChoice_parent:
                break;
            default:
                break;
        }
        
        value.answers.suffled { (left, right) -> Bool in
            return left === right;
        }
                
        return value;
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        var question : RNQuestionInfo! = object as? RNQuestionInfo;
        var value = false;
        
        guard question != nil else{
            return value;
        }
        
        guard self !== question else{
            return true;
        }
        
        guard self.reference === question?.reference
            && self.positive != question?.positive else{
            return value;
        }
        
        guard self.answers.count == question.answers.count else{
            return value;
        }
        
        value = true;
        
        self.answers.forEach { (answer) in
            value = value && question.answers.contains(where: { (ans) -> Bool in
                return answer.title == ans.title;
            });
        }
        
        return value;
    }
}
