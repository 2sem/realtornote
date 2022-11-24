//
//  DonateViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2022/11/16.
//  Copyright © 2022 leesam. All rights reserved.
//

import UIKit

class DonateViewController: UIViewController {

    @IBOutlet weak var backgroundView: UIVisualEffectView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet var messageLabels: [UILabel]!
    let config = LSRemoteConfig.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.iconImageView.isVisible = config.isDonationIconVisible
        debugPrint("config isDonationIconVisible[\(config.isDonationIconVisible)]")
        let msgIndex = config.donationMsgType.rawValue - 1
        debugPrint("config donationMsgType[\(config.donationMsgType)]")
        self.messageLabels.enumerated().forEach { item in
            item.element.isVisible =  item.offset == msgIndex
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.backgroundView.isVisible = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.backgroundView.isVisible = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
