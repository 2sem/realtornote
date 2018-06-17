//
//  AppDelegate.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 24..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds
import UserNotifications
import LSExtensions

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GADInterstialManagerDelegate, ReviewManagerDelegate, GADRewardManagerDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var fullAd : GADInterstialManager?;
    var rewardAd : GADRewardManager?;
    var reviewManager : ReviewManager?;

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        GADMobileAds.configure(withApplicationID: "ca-app-pub-9684378399371172~7124016405");
        FirebaseApp.configure()
        
        self.rewardAd = GADRewardManager(self.window!, unitId: GADInterstitial.loadUnitId(name: "RewardAd") ?? "", interval: 60.0 * 60.0 * 24); //
        self.rewardAd?.delegate = self;

        self.reviewManager = ReviewManager(self.window!, interval: 60.0 * 60 * 24 * 3); //
        self.reviewManager?.delegate = self;
        //self.reviewManager?.show();
        
        self.fullAd = GADInterstialManager(self.window!, unitId: GADInterstitial.loadUnitId(name: "FullAd") ?? "", interval: 60.0 * 60 * 3); //60.0 * 60 * 3
        self.fullAd?.delegate = self;
        self.fullAd?.canShowFirstTime = false;
        self.fullAd?.show();
        
        UNUserNotificationCenter.current().delegate = self;
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (result, error) in
            guard result else{
                return;
            }
            
            DispatchQueue.main.syncInMain {
                application.registerForRemoteNotifications();
            }
        }
        
        /**
         Nodejs:
         {
            title: ..
            body: ..
            sound: "default",
            topic: "com.y2k..."
            payload: {
                category: category,
                item: item
            }
        }
         */
        if let push = launchOptions?[.remoteNotification] as? [String: AnyObject]{
            let noti = push["aps"] as! [String: AnyObject];
            let alert = noti["alert"] as! [String: AnyObject];
            let title = alert["title"] as? String ?? "";
            let body = alert["body"] as? String ?? "";
            //Custom data can be receive from 'aps' not 'alert'
            let category = push["category"] as? String ?? "";
            //let url = push["url"] as? String ?? "";
            
            self.performPushCommand(title, body: body, category: category, payload: push);
            print("launching with push[\(push)]");
        }else if let launchUrl = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL{
            //self.openKakaoUrl(launchUrl);
        }
        
        return true
    }
    
    func performPushCommand(_ title : String, body : String, category : String, payload : [String : AnyObject]){
        let category = RNPushController.Category(rawValue: category);
        print("parse push command. category[\(category)] title[\(title)] body[\(body)]");
        
        switch category{
        case .notice?, .news?, .quiz?, .update?:
            guard let url = URL(string: payload["url"] as? String ?? "") else{
                return;
            }
            MainViewController.startingUrl = url;
            break;
        default:
            print("receive unkown command. category[\(category.debugDescription)]");
            break;
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.scheme == "kakaod3be13c89a776659651eef478d4e4268" else {
            return false;
        }
        
        //RNInfoTableViewController.startingQuery = url;
        return true;
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        guard self.reviewManager?.canShow ?? false else{
            self.fullAd?.show();
            return;
        }
        self.reviewManager?.show();
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //.reduce("", {$0 + String(format: "%02X", $1)});
        RNPushController.shared.register(deviceToken.hexString);
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error)");
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }

    // MARK: GADInterstialManagerDelegate
    func GADInterstialGetLastShowTime() -> Date {
        return RNDefaults.LastFullADShown;
        //Calendar.current.component(<#T##component: Calendar.Component##Calendar.Component#>, from: <#T##Date#>)
    }
    
    func GADInterstialUpdate(showTime: Date) {
        RNDefaults.LastFullADShown = showTime;
    }
    
    func GADInterstialWillLoad() {
        //RNInfoTableViewController.shared?.needAds = false;
        //RNFavoriteTableViewController.shared?.needAds = false;
    }
    
    // MARK: ReviewManagerDelegate
    func reviewGetLastShowTime() -> Date {
        return RNDefaults.LastShareShown;
    }
    
    func reviewUpdate(showTime: Date) {
        RNDefaults.LastShareShown = showTime;
    }
    
    // MARK: GADRewardManagerDelegate
    func GADRewardGetLastShowTime() -> Date {
        return RNDefaults.LastRewardADShown;
    }
    
    func GADRewardUpdate(showTime: Date) {
        
    }
    
    func GADRewardUserCompleted() {
        RNDefaults.LastRewardADShown = Date();
    }
    
    // MARK: UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //update app
        print("receive push notification in foreground. identifier[\(notification.request.identifier)] title[\(notification.request.content.title)] body[\(notification.request.content.body)]");
        
        //UNNotificationPresentationOptions
        completionHandler([.alert, .sound]);
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("receive push. title[\(response.notification.request.content.title)] body[\(response.notification.request.content.body)] userInfo[\(response.notification.request.content.userInfo)]");
        let userInfo = response.notification.request.content.userInfo;
        let category = userInfo["category"] as? String;
        let item = userInfo["item"] as? String;
        self.performPushCommand(response.notification.request.content.title, body: response.notification.request.content.body, category: category ?? "", payload: userInfo as? [String : AnyObject] ?? [:]);
        /*if let push = launchOptions?[.remoteNotification] as? [String: AnyObject]{
         let noti = push["aps"] as! [String: AnyObject];
         let alert = noti["alert"] as! [String: AnyObject];
         RSSearchTableViewController.startingKeyword = alert["body"] as? String ?? "";
         print("launching with push[\(push)]");
         }*/
        completionHandler();
    }
}

