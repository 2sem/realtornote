//
//  CGRect+.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/26.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit

extension CGRect{
    init(center: CGPoint, size: CGSize) {
      self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
}

