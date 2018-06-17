//
//  RNPushController.swift
//  realtornote
//
//  Created by 영준 이 on 2018. 6. 5..
//  Copyright © 2018년 leesam. All rights reserved.
//

import Foundation

import UIKit
import LSExtensions
import Alamofire

/**
 [features]
 compay list for the keyword
 list of keyword
 favorite keywords
 favorite company
 
 [rest api]
 */

class RNPushController: NSObject {
    //    typealias ListCompletionHandler = ([RSStockItem]?, NSError?) -> Void;
    static let plistName = "realtornote";
    
    static func property(_ name: String) -> String{
        guard let plist = Bundle.main.path(forResource: self.plistName, ofType: "plist") else{
            preconditionFailure("Please create plist file named of \(UIApplication.shared.displayName ?? ""). file[\(self.plistName).plist]");
        }
        
        guard let dict = NSDictionary.init(contentsOfFile: plist) as? [String : String] else{
            preconditionFailure("Please \(self.plistName).plist is not Property List.");
        }
        
        return dict[name] ?? "";
    }
    
    static var pushPort : Int = {
        return Int(property("PushPort")) ?? 0;
    }()
    static var PushUrl : URL! = {
        return URL(string: "\(property("ServerURL")):\(pushPort)");
    }()
    
    static let PushRegURL = RNPushController.PushUrl.appendingPathComponent("devices/insert");
    
    static let shared = RNPushController();
    var deviceToken : String?;
    
    enum Category : String{
        case notice = "notice"
        case news = "news"
        case quiz = "quiz"
        case update = "update"
    }
    
    func register(_ device : String){
        let params = ["type":"ios","device":device];
        self.deviceToken = device;
        print("APNs device[\(self.deviceToken ?? "")] => \(type(of: self).PushRegURL.absoluteString)");
        Alamofire.request(type(of: self).PushRegURL, method: .post, parameters: params, encoding: JSONEncoding.default)
            .responseJSON { (res) in
                guard res.error == nil else{
                    print("push reg. error[\(res.error.debugDescription)]");
                    return;
                }
                
                print("push reg. result[\(res.response?.description ?? "")]");
        }
    }
}
