//
//  MainViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 24..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import Firebase

class RNTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func moveToPart(_ part : RNPartInfo){
        let subject = part.chapter?.subject;
        
        self.selectedIndex = Int(subject?.no ?? 0) - 1;
        LSDefaults.LastSubject = self.selectedIndex;

        let nav = self.selectedViewController as? UINavigationController;
        let view = nav?.viewControllers.first as? RNSubjectViewController;
        view?.part = part;
    }

    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        LSDefaults.LastSubject = tabBar.items?.index(of: item) ?? 0;
        Analytics.logLeesamEvent(.selectSubject, parameters: [:]);
        AppDelegate.sharedGADManager?.show(unit: .full);
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
