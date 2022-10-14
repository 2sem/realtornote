//
//  MainViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2018. 2. 17..
//  Copyright © 2018년 leesam. All rights reserved.
//

import UIKit
import FirebaseCrashlytics
import SafariServices
import FirebaseAnalytics

class MainViewController: UIViewController {

    class Urls{
        static let qnet : URL! = URL(string: "http://www.q-net.or.kr/man001.do?gSite=L&gId=08");
        static let realtornote : URL! = URL(string: "http://andy1002.cafe24.com/gnu_house");
        static let quiz : URL! = URL(string: "http://landquiz.com/bbs/gichul.php");
    }
    
    static var startingUrl : URL!{
        didSet{
            guard let url = startingUrl else{
                return;
            }
            
            shared?.openUrl(url);
        }
    }
    private(set) static var shared : MainViewController!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MainViewController.shared = self;
        if let url = MainViewController.startingUrl{
            MainViewController.startingUrl = nil;
            
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                self?.openUrl(url);
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        //Crashlytics.sharedInstance().crash();
    }
    
    @IBAction func onOpenQnet(_ button: UIButton) {
        Analytics.logLeesamEvent(.openQNet, parameters: [:]);
        //AppDelegate.sharedGADManager?.show(unit: .full) { [weak self](unit, ad) in
            self.openWithSafari(Urls.qnet, animated: true);
        //}
    }
    
    @IBAction func onOpenHome(_ button: UIButton) {
        Analytics.logLeesamEvent(.openQuizWin, parameters: [:]);
        //AppDelegate.sharedGADManager?.show(unit: .full) { [weak self](unit, ad) in
            self.openWithSafari(Urls.realtornote, animated: true);
        //}
    }
    
    @IBAction func onOpenQuiz(_ sender: UIButton) {
        Analytics.logLeesamEvent(.openQuizWin, parameters: [:]);
        //AppDelegate.sharedGADManager?.show(unit: .full) { [weak self](unit, ad) in
            self.openWithSafari(Urls.quiz, animated: true);
        //}
    }
    
    func openUrl(_ url : URL){
        var nav = self.presentedViewController as? UINavigationController;
        guard let internetView = self.storyboard?.instantiateViewController(withIdentifier: "internetView") as? RNInternetViewController else{
            return;
        }
        
        internetView.startingUrl = url.absoluteString;
        internetView.hidesBottomBarWhenPushed = true;
        
        //DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            AppDelegate.sharedGADManager?.show(unit: .full) { [weak self](unit, ad, result) in
                if nav != nil{
                    nav?.pushViewController(internetView, animated: true);
                }else if let tabView = self?.children.first(where: {$0 is RNTabBarController }) as? RNTabBarController {
                    nav = tabView.viewControllers?[tabView.selectedIndex] as? UINavigationController;
                    nav?.pushViewController(internetView, animated: true);
                }
            }
        //}
    }

    @IBAction func onDonate(_ button: UIButton) {
        Analytics.logLeesamEvent(.pressDonate, parameters: [:]);
        //GADRewardManager.shared?.show(true);
        AppDelegate.sharedGADManager?.show(unit: .donate, completion: nil);
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let nav = segue.destination as? UINavigationController{
            guard nav.topViewController is RNInternetViewController else{
                return;
            }
        }
    }
 

}
