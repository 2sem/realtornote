//
//  MainViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2018. 2. 17..
//  Copyright © 2018년 leesam. All rights reserved.
//

import UIKit
import Crashlytics

class MainViewController: UIViewController {

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
            self.openUrl(url);
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        //Crashlytics.sharedInstance().crash();
    }
    
    func openUrl(_ url : URL){
        var nav = self.presentedViewController as? UINavigationController;
        guard let internetView = self.storyboard?.instantiateViewController(withIdentifier: "internetView") as? RNInternetViewController else{
            return;
        }
        
        internetView.startingUrl = url.absoluteString;
        internetView.hidesBottomBarWhenPushed = true;
        
        if nav != nil{
            nav?.pushViewController(internetView, animated: true);
        }else if let tabView = self.childViewControllers.first(where: {$0 is RNTabBarController }) as? RNTabBarController {
            nav = tabView.viewControllers?[tabView.selectedIndex] as? UINavigationController;
            nav?.pushViewController(internetView, animated: true);
        }
    }

    @IBAction func onDonate(_ button: UIButton) {
        GADRewardManager.shared?.show(true);
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let nav = segue.destination as? UINavigationController{
            guard let internetView = nav.topViewController as? RNInternetViewController else{
                return;
            }
            
            switch segue.identifier ?? ""{
                case "qnet":
                    internetView.startingUrl = "http://www.q-net.or.kr/man001.do?gSite=L&gId=08";
                    break;
                case "realtornote":
                    internetView.startingUrl = "http://andy3938.cafe24.com/gnu_house";
                    break;
                case "quizwin":
                    internetView.startingUrl = "http://quizwin.co.kr/studyroom/refexam.asp";
                    break;
                default:
                    break;
            }
        }
    }
 

}
