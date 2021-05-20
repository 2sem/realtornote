//
//  RNInternetViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2018. 2. 17..
//  Copyright © 2018년 leesam. All rights reserved.
//

import UIKit
import ProgressWebViewController
import KakaoLink
import KakaoMessageTemplate
import FirebaseAnalytics

class RNInternetViewController: ProgressWebViewController {
    
    var originalRightButtons : [UIBarButtonItem] = [];
    @objc var startingUrl : String = "";
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.toolbarItemTypes = [.back, .forward, .reload];
        self.websiteTitleInNavigationBar = false;
    }
    
    override func viewDidLoad() {
        self.originalRightButtons = self.navigationItem.rightBarButtonItems ?? [];
        self.toolbarItemTypes = [.back, .forward, .flexibleSpace, .reload];
        super.viewDidLoad();
        // Do any additional setup after loading the view.
        //self.url = DASponsor.Urls.historyUrl;
        //self.load(DASponsor.Urls.historyUrl);
        
        //self.navigationItem.rightBarButtonItems = [];
        let url = URL(string: self.startingUrl);
        if url != nil{
            self.load(url!);
        }
        self.websiteTitleInNavigationBar = true;
        self.hidesBottomBarWhenPushed = false;
        //self.navigationController?.isNavigationBarHidden = false;
        //self.toolbarController?.toolbar.isHidden = true;
        //self.updateBarButtonItems()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.setScreenName(for: self);
    }
    //        self.navigationController?.navigationBar.setBackgroundImage(UIImage, for: .default);
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    //        guard self.url != nil else{
}
