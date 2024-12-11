//
//  LSRemoteConfig.swift
//  realtornote
//
//  Created by 영준 이 on 2022/11/18.
//  Copyright © 2022 leesam. All rights reserved.
//

import UIKit
import FirebaseRemoteConfig

class LSRemoteConfig: NSObject {
    class ConfigNames{
        static let isDonationIconVisible = "donation_icon";
        static let donationMsgType = "donation_msg_type";
        static let isDonationMsgCentered = "donation_msg_centered";
    }
    
    static let shared = LSRemoteConfig();
    
    var isServerAlive : Bool = true;
    lazy var firebaseConfig = RemoteConfig.remoteConfig();
    
    var isDonationIconVisible : Bool{
        return self.firebaseConfig.configValue(forKey: ConfigNames.isDonationIconVisible).boolValue ;
    }
    
    var donationMsgType : DonationMsgType{
        let value = self.firebaseConfig.configValue(forKey: ConfigNames.donationMsgType).numberValue.intValue
        return .init(rawValue: value) ?? .msgWithGuide;
    }
    
    var isDonationMsgCentered : Bool{
        return self.firebaseConfig.configValue(forKey: ConfigNames.isDonationMsgCentered).boolValue ;
    }
    
    override init() {
        super.init();
        self.firebaseConfig.setDefaults([ConfigNames.isDonationIconVisible : false as NSObject]);
    }
    
    func fetch(_ timeout: TimeInterval = 3.0, completion: ((LSRemoteConfig, Error?) -> Void)? = nil){
        //SWToast.activity("버전 정보 확인 중");
        /*self.firebaseConfig.fetchAndActivate { [unowned self](status, error) in
         SWToast.hideActivity();
         completion(self, error);
         }*/
        debugPrint("Start loading Remote Config")
        self.firebaseConfig.fetch(withExpirationDuration: timeout) { (status, error_fetch) in
            guard let rcerror = error_fetch else{
                debugPrint("Remote Config Loaded")
                self.firebaseConfig.activate{(result, errorAct) in
                    //SWToast.hideActivity();
                    completion?(self, errorAct);
                };
                return;
            }
            
            //SWToast.hideActivity();
            debugPrint("Remote Config Error \(rcerror)")
            completion?(self, rcerror);
        }
    }
}
