//
//  UIApplication+.swift
//  App
//
//  Created by 영준 이 on 1/7/26.
//

import UIKit

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    var keyRootViewController: UIViewController? {
        firstKeyWindow?.rootViewController
    }
}
