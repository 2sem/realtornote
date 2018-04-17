//
//  MainViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2018. 2. 17..
//  Copyright © 2018년 leesam. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
