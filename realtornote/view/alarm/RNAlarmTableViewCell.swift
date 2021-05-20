//
//  RNAlarmTableViewCell.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/30.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit

class RNAlarmTableViewCell: UITableViewCell {

    var info : RNAlarmModel!{
        didSet{
            self.updateInfo();
        }
    }
    
    var isFirst : Bool = false{
        didSet{
            self.deleteButton?.isHidden = self.isFirst
        }
    }
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var subjectNameLabel : UILabel!;
    @IBOutlet weak var partNameLabel : UILabel!;
    @IBOutlet weak var alarmTimeLabel : UILabel!;
    @IBOutlet weak var alarmSwitch : UISwitch!;
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    var deleteHandler : ((RNAlarmTableViewCell) -> Void)?;
    func setDeleteHandler(_ completion: @escaping (RNAlarmTableViewCell) -> Void){
        self.deleteHandler = completion;
    }
    
    typealias EnableCompletion = (_ enabled: Bool, _ completion: @escaping (Bool) -> Void) -> Void;
    var enableHandler : EnableCompletion?;
    func setEnableHandler(_ completion: @escaping EnableCompletion){
        self.enableHandler = completion;
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateInfo(){
        guard let info = self.info else{
            return;
        }
        
        self.subjectNameLabel.text = info.subject?.name;
//        self.courseNameLabel.text = info.courseName;
        self.alarmSwitch.isSelected = info.enabled;
        self.updateAlarmInfo();
    }
    
    func updateAlarmInfo(_ exceptSwitch: Bool = false){
        guard let info = self.info else{
            return;
        }
        
        let alarmTime = info.alarmDescription;
        let enabled = info.enabled;
//        Crashlytics.crashlytics().recordValue(alarmTime, property: .StudyHelperAlarmTime);
        self.alarmTimeLabel?.text = "";
        if !exceptSwitch{
            self.alarmSwitch.isOn = enabled;
        }
        self.updateSwitchColor();
        
        self.containerView.backgroundColor = enabled ? #colorLiteral(red: 0, green: 0.6672878265, blue: 0.9834814668, alpha: 0.3) : #colorLiteral(red: 0.976395905, green: 0.9765127301, blue: 0.9763562083, alpha: 1);
        self.containerView.borderUIColor = enabled ? #colorLiteral(red: 0, green: 0.6672878265, blue: 0.9834814668, alpha: 0.1) : #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1);
        
        self.subjectNameLabel.isHidden = true;
//        self.subjectNameLabel.text = info.subject?.name ?? "최근 과목";
//        self.partNameLabel.isHidden = info.subject?.name == nil;
//        if let subjectName = info.subject?.name{
        self.partNameLabel.text = info.subject?.name ?? "최근 과목";
//            self.partNameLabel.isHidden = false;
//        }
//        if let title = info.title{
            self.alarmTimeLabel.text = alarmTime;
//            self.partNameLabel.isHidden = false;
//        }
        
        self.subjectNameLabel.isHighlighted = !enabled;
        self.partNameLabel.isHighlighted = !enabled;
        self.alarmTimeLabel.isHighlighted = !enabled;
    }
    
    func updateSwitchColor(){
        if self.alarmSwitch.isOn{
            self.alarmSwitch.thumbTintColor = #colorLiteral(red: 0.1886929572, green: 0.4163666964, blue: 0.951190412, alpha: 1);
            self.alarmSwitch.onTintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1);
//            self.iconImageView.image = #imageLiteral(resourceName: "icoStudyhelperA");
        }else{
            self.alarmSwitch.thumbTintColor = #colorLiteral(red: 0.937254902, green: 0.937254902, blue: 0.9568627451, alpha: 1);
            self.alarmSwitch.onTintColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1);
//            self.iconImageView.image = #imageLiteral(resourceName: "icoStudyhelperN");
        }
    }

    var isUpdating : Bool = false;
    @IBAction func onToggleAlarm(_ button : UISwitch){
        button.isUserInteractionEnabled = false;
//        button.isOn = !button.isOn;
//        self.updateSwitchColor();
        
        guard !isUpdating else{
            button.isUserInteractionEnabled = true;
            self.isUpdating = false;
            return;
        }
        
        self.enableHandler?(button.isOn){ [weak self](result) in
            button.isUserInteractionEnabled = true;
            guard !result else{
                self?.updateAlarmInfo(true);
                return;
            }
            
            //rollbacks if toggle processing has been failed
            button.isOn = !button.isOn;
            self?.isUpdating = true;
            self?.updateSwitchColor();
        }
        //self.delegate?.studyHelperCell(toggleCell: self, enabled: !control.isOn);
    }
    
    @IBAction func onDelete(_ button : UIButton){
        //self.delegate?.studyHelperCell(deleteCell: self);
        self.deleteHandler?(self);
    }

}
