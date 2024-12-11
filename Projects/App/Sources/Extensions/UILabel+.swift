//
//  UILabel+.swift
//  realtornote
//
//  Created by 영준 이 on 2022/11/23.
//  Copyright © 2022 leesam. All rights reserved.
//

import UIKit

extension UILabel {
    @IBInspectable
    @available(iOS 14, *)
    var isKorean: Bool {
        set(value) {
            self.lineBreakStrategy =  .hangulWordPriority
        }
        
        get {
            return self.lineBreakStrategy == .hangulWordPriority
        }
    }
}
