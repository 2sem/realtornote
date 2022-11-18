//
//  Analytics+.swift
//  realtornote
//
//  Created by 영준 이 on 2019. 6. 28..
//  Copyright © 2019년 leesam. All rights reserved.
//

import UIKit
import FirebaseAnalytics

//extension UIViewController{
//    func setAnalyticScreenName(){
//        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventScreenView, parameters: <#T##[String : Any]?#>)
////        Analytics.setScreenName(for: self);
//    }
//}

extension Analytics{
    static func setScreenName(for viewController: UIViewController){
        var name : String?;
        let className : String? = viewController.classForCoder.description().components(separatedBy: ".").last;
        
        if viewController is RNSubjectViewController{
            name = "과목탭";
        }else if viewController is RNPartViewController{
            name = "파트";
        }else if viewController is RNFavoriteTableViewController{
            name = "책갈피";
        }else if viewController is RNQuestionViewController{
            name = "퀴즈";
        }else if viewController is RNInternetViewController{
            name = "웹페이지";
        }
        
        var params : [String : Any] = [AnalyticsParameterScreenClass : type(of: self)];
        
        if let name = name{
            params[AnalyticsParameterScreenName] = name;
        }
        
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventScreenView,
                                             parameters: params);
        print("[\(#function)] set scree name for firebase analytics. name[\(name ?? "")] screen[\(className ?? "")]");
    }
    
    enum LeesamEvent : String{
        case selectSubject = "과목선택"
        case openChapterList = "챕터목록보기"
        case selectChapter = "챕터선택"
        case zoomIn = "확대"
        case zoomOut = "축소"
        case selectPart = "파트선택"
        case pressShare = "공유버튼선택"
        case startQuiz = "퀴즈시작"
        case finishQuiz = "퀴즈완료"
        case restartQuiz = "퀴즈재시작"
        case openFavorite = "책갈피열기"
        case openSearch = "검색어열기"
        case search = "검색실행"
        case onFavorite = "책갈피설정"
        case offFavorite = "책갈피설정해제"
        case openUrl = "웹페이지열기"
        case openQNet = "Qnet열기"
        case openCommuinty = "커뮤니티열기"
        case openQuizWin = "QuizWin열기"
        case pressDonate = "개발자후원클릭"
        case cancelDonation = "후원_다음에하기"
        case donate = "후원하기"
        case donationCompleted = "후원완료"
        case reviewAfterDonation = "후원_후_평가하기"
    }
    
    class SiwonEventProperty{
        static let autoPlay = "자동재생"
        static let course = "강좌번호"
        static let lecture = "강의번호"
        static let lectureTitle = "강의제목"
        static let lectureUrl = "강의파일"
        static let speed = "재생속도"
    }
    
    /*static func logSiwonEvent(_ event: SiwonEvent, parameters: [String : Any]? = nil){
        self.logEvent(event.rawValue, parameters: parameters);
    }*/
    
    static func logLeesamEvent(_ event: LeesamEvent, parameters: [String : Any] = [:]){
        let params : [String : Any] = [:];
        /*if let lecture = lecture{
            params[SiwonEventProperty.course] = lecture.course?.no ?? lecture.courseNo;
            params[SiwonEventProperty.lecture] = lecture.no;
            params[SiwonEventProperty.lectureTitle] = lecture.title;
            params[SiwonEventProperty.lectureUrl] = lecture.media?.absoluteString;
        }*/
        /*params.merge(parameters){ (left, right) in right }
        if let autoPlay = autoPlay{
            params[SiwonEventProperty.autoPlay] = autoPlay.description;
        }*/
        
        self.logEvent(event.rawValue, parameters: params);
    }
}

public extension UIViewController{
    func setAnalytlicScreen(name: String? = nil){
        
        
        
    }
}
