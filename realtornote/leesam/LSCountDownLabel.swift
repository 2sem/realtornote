//
//  LSCountDownLabel.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 8. 17..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import UIKit

class LSCountDownLabel : UILabel{
    @IBInspectable var seconds : Int = 0;
    var currentSecond = 0;
    //var fontSizeBackup : CGFloat = 0.0;
    
    var isCounting = false;
    
    override func awakeFromNib() {
        super.awakeFromNib();
    }
    
    func start(_ completion: @escaping (Int) -> Void){
        guard !self.isCounting else{
            return;
        }
        
        self.isCounting = true;
        self.currentSecond = self.seconds;
        //self.fontSizeBackup = self.font.pointSize;
        self.count(completion);
    }
    
    func stop(){
        guard self.isCounting else{
            return;
        }
        
        self.isCounting = false;
        self.layer.removeAllAnimations();
        self.transform = CGAffineTransform.identity;
        //self.font = self.font.withSize(self.fontSizeBackup);
    }
    
    private func count(_ completion: @escaping (Int) -> Void){
        //self.font = self.font.withSize(self.fontSizeBackup / 2.0);
        self.transform = CGAffineTransform.init(scaleX: 0.25, y: 0.25);
        self.text = "\(self.currentSecond)";
        
        guard self.isCounting  else{
            self.text = "";
            return;
        }
        
        UIView.animate(withDuration: 1.0, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            //self.font = self.font.withSize(self.fontSizeBackup);
            self.transform = CGAffineTransform.identity;
        }) { (result) in
            self.currentSecond = self.currentSecond - 1;
            
            guard self.currentSecond > 0 else{
                self.isCounting = false;
                completion(self.currentSecond);
                return;
            }
            
            self.count(completion);
        }
    }
}
