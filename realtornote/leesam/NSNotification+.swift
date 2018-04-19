//
//  NSNotification.swift
//  realtornote
//
//  Created by 영준 이 on 2018. 4. 17..
//  Copyright © 2018년 leesam. All rights reserved.
//

import Foundation
import UIKit

extension NSNotification{
    var keyboardFrame : CGRect{
        var value = (self.userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue;
        if value.height <= 0{
            value = (self.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        }
        
        return value;
    }
    
    var keyboardAniDuration : TimeInterval{
        return userInfo![UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval;
    }
}
