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
import FirebaseMessaging
import StoreKit
import GADManager

class AppDelegate: UIResponder, UIApplicationDelegate, ReviewManagerDelegate, GADRewardManagerDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    /// to access AppDelegate.window
    static var sharedWindow : UIWindow?{
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{
            return nil
        }
        
        return delegate.window;
    }
    
    enum GADUnitName : String{
        case full = "FullAd"
        case donate = "Donate";
        case launch = "Launch"
    }
    static var sharedGADManager : GADManager<GADUnitName>?;
    var rewardAd : GADRewardManager?;
    var reviewManager : ReviewManager?;
    let reviewInterval = 60;
    static var firebase : Messaging?;
    var appPermissionRequested = false
    
    override init() {
        super.init();
        String.Logger.console.level = .debug;
    }

    func _application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.windows.forEach { (win) in
            if #available(iOS 13.0, *) {
                win.overrideUserInterfaceStyle = .light
            }
        }
        
        FirebaseApp.configure();
        //GADMobileAds.sharedInstance().start(completionHandler: nil);
        Messaging.messaging().delegate = self;

        /*if let push_plist = Bundle.main.url(forResource: "GoogleService-Info-FCM", withExtension: "plist"),
            let push_firebase = FirebaseOptions.init(contentsOfFile: push_plist.path){
            FirebaseApp.configure(name: "FCM", options: push_firebase);
            Messaging.messaging().retrieveFCMToken(forSenderID: "672853607165") { (token, error) in
                print("plist fcm token[\(token)] error[\(error)]");
            };
        }*/
        
        self.rewardAd = GADRewardManager(self.window!, unitId: InterstitialAd.loadUnitId(name: "RewardAd") ?? "", interval: 60.0 * 60.0 * 24); //
        self.rewardAd?.delegate = self;

        self.reviewManager = ReviewManager(self.window!, interval: 60.0 * 60 * 24 * 3); //
        self.reviewManager?.delegate = self;
        //self.reviewManager?.show();
        
        var adManager = GADManager<GADUnitName>.init(self.window!);
        AppDelegate.sharedGADManager = adManager;
        adManager.delegate = self;
        #if DEBUG
        adManager.prepare(interstitialUnit: .full, interval: 60.0);
        adManager.prepare(interstitialUnit: .donate, interval: 60.0);
        adManager.prepare(openingUnit: .launch, isTesting: true, interval: 60.0); //
        #else
        adManager.prepare(interstitialUnit: .full, interval: 60.0); // * 60.0 * 1
        adManager.prepare(interstitialUnit: .donate, interval: 60.0); // * 60.0 * 1
        adManager.prepare(openingUnit: .launch, interval: 60.0 * 5); //
        #endif
        adManager.canShowFirstTime = true;
        LSDefaults.increaseLaunchCount();

        UNUserNotificationCenter.current().delegate = self;

        // Only request UserNotifications permission on iOS < 26
        // On iOS 26+, AlarmKit will be used and permission will be requested when needed
        if #unavailable(iOS 26.0) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (result, error) in
                defer{
                    RNAlarmManager.shared.sync();
                }

                guard result else{
                    return;
                }

                DispatchQueue.main.syncInMain {
                    application.registerForRemoteNotifications();
                }
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
        if let _ = launchOptions?[.remoteNotification] as? [String: AnyObject]{
            /*let noti = push["aps"] as! [String: AnyObject];
            let alert = noti["alert"] as! [String: AnyObject];
            let title = alert["title"] as? String ?? "";
            let body = alert["body"] as? String ?? "";
            //Custom data can be receive from 'aps' not 'alert'
            let category = push["category"] as? String ?? "";
            //let url = push["url"] as? String ?? "";
            
            self.performPushCommand(title, body: body, category: category, payload: push);
            print("launching with push[\(push)]");*/
        }else if let _ = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL{
            //
        }
        
        return true
    }
    
    func performPushCommand(_ title : String, body : String, category : String, payload : [String : AnyObject]){
        let cg = RNPushController.Category(rawValue: category);
        print("parse push command. category[\(category)] title[\(title)] body[\(body)]");
        if let alert = self.window?.rootViewController?.presentedViewController as? UIAlertController{
            alert.dismiss(animated: false){
                self.performPushCommand(title, body: body, category: category, payload: payload);
            }
            return;
        }
        
        switch cg{
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
        print("app enter background");
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        //RNInfoTableViewController.startingQuery = url;
        return true;
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("app enter foreground");
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("app become active");
        
        defer {
            LSDefaults.increaseLaunchCount();
        }
        
        guard LSDefaults.LaunchCount % reviewInterval > 0 else{
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            }else{
                self.reviewManager?.show();
            }
            return;
        }
        
        #if DEBUG
        let test = true;
        #else
        let test = false;
        #endif
        
        appPermissionRequested = appPermissionRequested || LSDefaults.requestAppTrackingIfNeed()
        guard appPermissionRequested else{
            debugPrint("App doesn't allow launching Ads. appPermissionRequested[\(appPermissionRequested)]")
            return;
        }
        
        guard LSDefaults.AdsTrackingRequested else {
            return
        }
        
        AppDelegate.sharedGADManager?.show(unit: .launch, isTesting: test, completion: { (unit, ad, result) in
            
        })
        
        /*guard self.reviewManager?.canShow ?? false else{
            //self.fullAd?.show();
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AppDelegate.sharedGADManager?.show(unit: .full);
            }
            return;
        }
        
        self.reviewManager?.show();*/
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //.reduce("", {$0 + String(format: "%02X", $1)});
        //RNPushController.shared.register(deviceToken.hexString);
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error)");
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }

    // MARK: GADInterstialManagerDelegate
    func GADInterstialGetLastShowTime() -> Date {
        return LSDefaults.LastFullADShown;
        //Calendar.current.component(<#T##component: Calendar.Component##Calendar.Component#>, from: <#T##Date#>)
    }
    
    func GADInterstialUpdate(showTime: Date) {
        LSDefaults.LastFullADShown = showTime;
    }
    
    func GADInterstialWillLoad() {
        //RNInfoTableViewController.shared?.needAds = false;
        //RNFavoriteTableViewController.shared?.needAds = false;
    }
    
    // MARK: ReviewManagerDelegate
    func reviewGetLastShowTime() -> Date {
        return LSDefaults.LastShareShown;
    }
    
    func reviewUpdate(showTime: Date) {
        LSDefaults.LastShareShown = showTime;
    }
    
    // MARK: GADRewardManagerDelegate
    func GADRewardGetLastShowTime() -> Date {
        return LSDefaults.LastRewardADShown;
    }
    
    func GADRewardUpdate(showTime: Date) {
        
    }
    
    func GADRewardUserCompleted() {
        LSDefaults.LastRewardADShown = Date();
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
        //let item = userInfo["item"] as? String;
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

extension AppDelegate : MessagingDelegate{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("fcm device[\(fcmToken ?? "")]");
        let topic = "notice";
        //let topic = "congress_2_9770881_law";
        type(of: self).firebase = messaging;
        messaging.subscribe(toTopic: topic) { (error) in
            print("fcm messaging error[\(error?.localizedDescription ?? "")]");
        }
        //messaging.unsubscribe(fromTopic: topic);
    }
}

extension AppDelegate : GADManagerDelegate{
    typealias E = GADUnitName
    
    func GAD<E>(manager: GADManager<E>, lastPreparedTimeForUnit unit: E) -> Date where E : Hashable, E : RawRepresentable, E.RawValue == String {
//        let now = Date();
  //        if RSDefaults.LastOpeningAdPrepared > now{
  //            RSDefaults.LastOpeningAdPrepared = now;
  //        }

          return LSDefaults.LastOpeningAdPrepared;
          //Calendar.current.component(<#T##component: Calendar.Component##Calendar.Component#>, from: <#T##Date#>)
    }
    
    func GAD<E>(manager: GADManager<E>, updateLastPreparedTimeForUnit unit: E, preparedTime time: Date){
        LSDefaults.LastOpeningAdPrepared = time;
        
        //RNInfoTableViewController.shared?.needAds = false;
        //RNFavoriteTableViewController.shared?.needAds = false;
    }
    
    func GAD<E>(manager: GADManager<E>, didDismissADForUnit unit: E) where E : Hashable, E : RawRepresentable, E.RawValue == String {
        LSDefaults.increateAdsShownCount();
    }
    
    func GAD<GADUnitName>(manager: GADManager<GADUnitName>, updatShownTimeForUnit unit: GADUnitName, showTime time: Date){
        let now = Date();
        if LSDefaults.LastFullADShown > now{
            LSDefaults.LastFullADShown = now;
        }
        
        LSDefaults.LastFullADShown = time;
        //LSDefaults.increaseLaunchCount();
        //GHStoreManager.shared.tokenPurchased(1);
    }
    
    func GAD<GADUnitName>(manager: GADManager<GADUnitName>, lastShownTimeForUnit unit: GADUnitName) -> Date{
        return LSDefaults.LastFullADShown;
    }
    
    func GAD<GADUnitName>(manager: GADManager<GADUnitName>, willPresentADForUnit unit: GADUnitName){
        
    }
}

