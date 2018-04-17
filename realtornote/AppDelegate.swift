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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GADInterstialManagerDelegate, ReviewManagerDelegate {

    var window: UIWindow?
    var fullAd : GADInterstialManager?;
    var reviewManager : ReviewManager?;

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        GADMobileAds.configure(withApplicationID: "ca-app-pub-9684378399371172~7124016405");
        FirebaseApp.configure()
        
        self.reviewManager = ReviewManager(self.window!, interval: 60.0 * 60 * 24 * 3); //
        self.reviewManager?.delegate = self;
        //self.reviewManager?.show();
        
        self.fullAd = GADInterstialManager(self.window!, unitId: GADInterstitial.loadUnitId(name: "FullAd") ?? "", interval: 60.0 * 60 * 3); //60.0 * 60 * 3
        self.fullAd?.delegate = self;
        self.fullAd?.canShowFirstTime = false;
        self.fullAd?.show();

        return true
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
}

