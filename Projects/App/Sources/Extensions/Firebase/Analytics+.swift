//
//  Analytics+.swift
//  realtornote
//
//  Created by 영준 이 on 2019. 6. 28..
//  Copyright © 2019년 leesam. All rights reserved.
//

import FirebaseAnalytics

extension Analytics {
    enum LeesamEvent : String {
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
        case openRealtorRaw = "공인중개사법열기"
        case pressDonate = "개발자후원클릭"
        case cancelDonation = "후원_다음에하기"
        case donate = "후원하기"
        case donationCompleted = "후원완료"
        case reviewAfterDonation = "후원_후_평가하기"
    }

    static func logLeesamEvent(_ event: LeesamEvent, parameters: [String : Any] = [:]) {
        self.logEvent(event.rawValue, parameters: parameters)
    }
}
