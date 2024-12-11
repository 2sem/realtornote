//
//  UIView+.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/26.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit

extension UIView{
    /// Whether to be changed when the device is on dark mode or color inversed
    @IBInspectable public var ignoresDarkMode: Bool {
        get {
            if #available(iOS 11.0, *) {
                return self.accessibilityIgnoresInvertColors
            }
            return false
        }
        set(value) {
            if #available(iOS 11.0, *) {
                self.accessibilityIgnoresInvertColors = value;
            }
        }
    }
}
