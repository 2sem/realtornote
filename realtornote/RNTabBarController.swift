//
//  MainViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 24..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import FirebaseAnalytics

class RNTabBarController: UITabBarController {

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
    private(set) static var shared : RNTabBarController!;
    
    var barHeight : CGFloat = 0;
    var margin: UIEdgeInsets = .init(top: 0, left: 0, bottom: 44, right: 0);
    @IBInspectable var leftMargin : CGFloat{
        get{ self.margin.left }
        set{ self.margin.left = newValue }
    }
    @IBInspectable var topMargin : CGFloat{
        get{ self.margin.top }
        set{ self.margin.top = newValue }
    }
    @IBInspectable var rightMargin : CGFloat{
        get{ self.margin.right }
        set{ self.margin.right = newValue }
    }
    @IBInspectable var bottomMargin : CGFloat{
        get{ self.margin.bottom }
        set{ self.margin.bottom = newValue }
    }
    
    @IBOutlet var newsContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        type(of: self).shared = self;

        self.barHeight = self.tabBar.frame.height + self.margin.top + self.margin.bottom;
        self.newsContainer.frame.size.height = self.margin.bottom;
        
        //Updates if excel file is new version
        if RNExcelController.Default.needToUpdate{
            RNExcelController.Default.loadFromFlie();
            
            //Syncs groups and persons to database
            RNModelController.shared.sync(RNExcelController.Default);
        }
        
        //Applys names of subjects to the tab titles
        for (i, viewController) in (self.viewControllers ?? []).enumerated(){
            guard let subject = RNModelController.shared.findSubject(i + 1) else{
                return;
            }
            
            let nav = viewController as? UINavigationController;
            let subjectView = nav?.visibleViewController as? RNSubjectViewController;
            
            viewController.tabBarItem.title = subject.name;
            subjectView?.subject = subject;
        }
        
        //Go to last subject user saw
        self.selectedIndex = LSDefaults.LastSubject;
        
        if let url = type(of: self).startingUrl{
            type(of: self).startingUrl = nil;
            
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                self?.openUrl(url);
            }
        }
        
        self.setupBottomBanner();
        
        self.fixNavigationBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var bottomInset : CGFloat = 0;
        if #available(iOS 11.0, *) {
            bottomInset = self.view.safeAreaInsets.bottom;
        }
        self.tabBar.frame.size.height = self.barHeight + bottomInset;
        self.tabBar.frame.origin.y = self.view.frame.height - bottomInset - self.barHeight;
        
        self.newsContainer.frame.origin.x = 20;
        self.newsContainer.frame.size.width = self.tabBar.frame.size.width - 20 * 2;
        self.newsContainer.frame.origin.y = self.tabBar.frame.size.height - self.newsContainer.frame.height - bottomInset;
    }
    
    func fixNavigationBar(){
        guard #available(iOS 15, *) else { return }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    func fixTabBar(){
        guard #available(iOS 15, *) else { return }
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    func setupBottomBanner(){
        self.tabBar.items?.forEach({ (item) in
            item.imageInsets.top = self.margin.top - self.margin.bottom;
            item.imageInsets.bottom = 0; //self.margin.bottom;
            item.titlePositionAdjustment.vertical = item.titlePositionAdjustment.vertical - self.margin.bottom;
        })
        
        self.tabBar.addSubview(self.newsContainer);
        //self.tabBar.bringSubviewToFront(self.newsContainer);
        self.newsContainer.bringSubviewToFront(self.tabBar)
    }
    func moveToPart(_ part : RNPartInfo){
        let subject = part.chapter?.subject;
        
        self.selectedIndex = Int(subject?.no ?? 0) - 1;
        LSDefaults.LastSubject = self.selectedIndex;

        let nav = self.selectedViewController as? UINavigationController;
        let subjectView = nav?.viewControllers.first as? RNSubjectViewController;
        
        if let chapter = part.chapter{
            subjectView?.chapter = chapter;
            subjectView?.select(chapter: chapter);
        }
        
        subjectView?.part = part;
    }

    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        LSDefaults.LastSubject = tabBar.items?.index(of: item) ?? 0;
        Analytics.logLeesamEvent(.selectSubject, parameters: [:]);
        //AppDelegate.sharedGADManager?.show(unit: .full);
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
    
    @IBAction func onDonate(_ button: UIButton) {
        Analytics.logLeesamEvent(.pressDonate, parameters: [:]);
        //GADRewardManager.shared?.show(true);
//        guard let donateController = self.storyboard?.instantiateViewController(withIdentifier: "donate") else {
//            return
//        }
        
//        AppDelegate.sharedGADManager?.show(unit: .donate, completion: nil);
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
