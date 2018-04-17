//
//  GADBannerView+.swift
//  democracyaction
//
//  Created by 영준 이 on 2017. 7. 6..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import GoogleMobileAds

/**
 GoogleADUnitID/{name}
 */
extension GADBannerView {
    func loadUnitId(_ name : String){
        var unitList = Bundle.main.infoDictionary?["GoogleADUnitID"] as? [String : String];
        guard unitList != nil else{
            print("Add [String : String] Dictionary as 'GoogleADUnitID'");
            return;
        }
        
        guard !(unitList ?? [:]).isEmpty else{
            print("Add Unit into 'GoogleADUnitID'");
            return;
        }
        
        var unit = unitList?[name];
        guard unit != nil else{
            print("Add unit \(name) into GoogleADUnitID");
            return;
        }
        
        self.adUnitID = unit;
    }
}
