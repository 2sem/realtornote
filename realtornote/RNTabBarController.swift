//
//  MainViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 24..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit

class RNTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //var recognizer = LSDocumentRecognizer();
        //recognizer.recognize(doc: "1) hah hoho ", symbols: []);
        
        if RNExcelController.Default.needToUpdate{
            RNExcelController.Default.loadFromFlie();
            
            //sync groups and persons to database
            RNModelController.shared.sync(RNExcelController.Default);
        }
        // Do any additional setup after loading the view.
        //apply tab title as names of subjects
        for (i, viewController) in (self.viewControllers ?? []).enumerated(){
            guard let subject = RNModelController.shared.findSubject(i+1) else{
                return;
            }
            
            let nav = viewController as? UINavigationController;
            let subjectView = nav?.visibleViewController as? RNSubjectViewController;
            
            viewController.tabBarItem.title = subject.name;
            subjectView?.subject = subject;
        }
        
        self.selectedIndex = RNDefaults.LastSubject;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func moveToPart(_ part : RNPartInfo){
        let subject = part.chapter?.subject;
        
        self.selectedIndex = Int(subject?.no ?? 0) - 1;
        RNDefaults.LastSubject = self.selectedIndex;

        let nav = self.selectedViewController as? UINavigationController;
        let view = nav?.viewControllers.first as? RNSubjectViewController;
        view?.part = part;
    }

    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        RNDefaults.LastSubject = tabBar.items?.index(of: item) ?? 0;
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
