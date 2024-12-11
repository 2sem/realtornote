//
//  LSLabel.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/26.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit

@IBDesignable
class LSLabel: UILabel {
    private var contentPaddingInsets : UIEdgeInsets = UIEdgeInsets.zero{
        didSet{
            self.invalidateIntrinsicContentSize();
        }
    }
    
    // MARK: Properties for Padding
    @IBInspectable var topPadding : CGFloat{
        get{
            return self.contentPaddingInsets.top;
        }
        set(value){
            self.contentPaddingInsets.top = value;
        }
    }
    
    @IBInspectable var bottomPadding : CGFloat{
        get{
            return self.contentPaddingInsets.bottom;
        }
        set(value){
            self.contentPaddingInsets.bottom = value;
        }
    }
    
    @IBInspectable var leftPadding : CGFloat{
        get{
            return self.contentPaddingInsets.left;
        }
        set(value){
            self.contentPaddingInsets.left = value;
        }
    }
    
    @IBInspectable var rightPadding : CGFloat{
        get{
            return self.contentPaddingInsets.right;
        }
        set(value){
            self.contentPaddingInsets.right = value;
        }
    }
    
    var horizontalPadding : CGFloat{
        return self.leftPadding + self.rightPadding;
    }
    
    var verticalPadding : CGFloat{
        return self.topPadding + self.bottomPadding;
    }
    
    override func drawText(in rect: CGRect) {
        //let insets = UIEdgeInsets(top: self.topPadding, left: self.leftPadding, bottom: self.bottomPadding, right: self.rightPadding);
        super.drawText(in: rect.inset(by: self.contentPaddingInsets));
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: self.contentPaddingInsets);
        let rect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines);
        let paddingInsets = UIEdgeInsets(top: -self.contentPaddingInsets.top, left: -self.contentPaddingInsets.left, bottom: -self.contentPaddingInsets.bottom, right: -self.contentPaddingInsets.right)
        
        return rect.inset(by: paddingInsets);
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var value = super.intrinsicContentSize;
            //let textWidth = super.intrinsicContentSize.width - self.horizontalPadding
            //let textHeight = sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
            //let width = textWidth + self.horizontalPadding
            //let height = textHeight + self.verticalPadding
            
            
            //return CGSize(width: frame.width, height: height);
            value.height = value.height.advanced(by: self.topPadding + self.bottomPadding);
            value.width = value.width.advanced(by: self.leftPadding + self.rightPadding);
            
            return value;
        }
    }
}
