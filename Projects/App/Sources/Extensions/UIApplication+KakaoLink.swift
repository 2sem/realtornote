//
//  UIApplication+KakaoLink.swift
//  democracyaction
//
//  Created by 영준 이 on 2017. 7. 7..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import KakaoSDKShare
import KakaoSDKTemplate

extension UIApplication{
    func shareByKakao(){
        var urlComponents = URLComponents(string: "http://search.daum.net/search");
        urlComponents?.queryItems = [URLQueryItem(name: "q", value: "공인중개사요약집")]
        
        let kakaoLink = Link(webUrl: urlComponents!.url!);
        let kakaoContent = Content.init(title: UIApplication.shared.displayName ?? "",
                                        imageUrl: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Purple118/v4/f0/94/d4/f094d4c5-ae50-87db-4970-26a5a9c194c1/pr_source.png/150x150bb.jpg")!,
                                        imageWidth: 120,
                                        imageHeight: 120,
                                        description: "해외, 국내 여행시 외국인을 만나면 당황하셨나요?",
                                        link: kakaoLink)
        
        let kakaoTemplate = FeedTemplate.init(content: kakaoContent,
                                              buttons: [.init(title: "애플 앱스토어",
                                                              link: .init(webUrl: URL(string: "https://itunes.apple.com/us/app/id1265759928?mt=8"),
                                                                          mobileWebUrl: URL(string: "https://itunes.apple.com/us/app/id1265759928?mt=8"))),
                                                        .init(title: "구글플레이",
                                                                        link: .init(webUrl: URL(string: "https://play.google.com/store/apps/details?id=kr.co.joonhyun.realtorone&hl=ko"),
                                                                                    mobileWebUrl: URL(string: "https://play.google.com/store/apps/details?id=kr.co.joonhyun.realtorone&hl=ko")))])
        
        ShareApi.shared.shareDefault(templatable: kakaoTemplate) { result, error in
            guard let result = result else {
                print("kakao error[\(error.debugDescription )]")
                return
            }
            
            UIApplication.shared.open(result.url)
            print("kakao warn[\(result.warningMsg?.debugDescription ?? "")] args[\(result.argumentMsg?.debugDescription ?? "")]")
        }
    }
}
