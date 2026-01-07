//
//  UIApplication+.swift
//  App
//
//  Created by 영준 이 on 1/7/26.
//

import UIKit

extension UIApplication {
    var keyRootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        
        return windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    }
}
