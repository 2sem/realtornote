//
//  RNAlarmTableViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/18.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit

class RNAlarmTableViewController: UIViewController {
    var object : Any?;
    var weekDays : DateComponents.DateWeekDay = DateComponents.DateWeekDay.All;
    var time : DateComponents = DateComponents.init(hour: 0, minute: 0);
    
    @IBOutlet weak var weekdayScrollView: UIScrollView!
    @IBOutlet weak var weekdayStackView: UIStackView!
    @IBOutlet weak var timePicker: UIDatePicker!
        
    override func viewWillAppear(_ animated: Bool) {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.weekdayScrollView.contentInset.left = 8;
        self.weekdayScrollView.contentInset.right = 8;
        changeTimepickerInterval()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.timePicker.date = Calendar.current.date(from: self.time)!;
        self.updateDayButtons();
    }
    
    func changeTimepickerInterval() {
        #if DEBUG
        timePicker.minuteInterval = 1
        #else
        timePicker.minuteInterval = 5
        #endif
    }
    
    func updateDayButtons(){
        let days = self.weekDays;
        DateComponents.DateWeekDay.allWeekDays.forEach { (day) in
            guard let button = self.weekdayStackView.viewWithTag(day.weekday) as? UIButton else{
                return;
            }
            
            button.isSelected = days.contains(day);
            self.updateWeekButton(button);
        }
    }

    @IBAction func onToggleWeekDay(_ button: UIButton) {
        let day = DateComponents.DateWeekDay.allWeekDays[button.tag - 1];
        button.isSelected = !button.isSelected;
        self.updateWeekButton(button);
        if button.isSelected{
            self.weekDays.insert(day);
        }else{
            self.weekDays.subtract(day);
        }
    }
    
    @IBAction func onChangeTime(_ picker: UIDatePicker) {
        self.time = Calendar.current.dateComponents([.hour, .minute], from: picker.date);
        //self.helper.alarmTime = self.time;
        print("study helper alarm time changed. time[\(self.time)] object[\(self.object.debugDescription)]");
    }
    
    @IBAction func onSelectAll(_ button: UIButton) {
        if self.weekDays == .All{
            self.weekDays = DateComponents.DateWeekDay.init(rawValue: 0);
        }else{
            self.weekDays = DateComponents.DateWeekDay.All;
        }
        
        self.updateDayButtons();
    }
    
    func updateWeekButton(_ button : UIButton){
        button.backgroundColor = button.isSelected ? button.tintColor : UIColor.clear;
    }
    
    @IBAction func onApply(_ button: UIButton) {
        guard self.weekDays.days.any else{
//            SWToast.make(SWStrings.Messages.pleaseSelectAnyHelperDay, position: .center);
            return;
        }
        
        self.dismiss(animated: true){ [unowned self] in
//            self.delegate?.alarmSetting(self, weekday: self.weekDays, time: self.time, object: self.object);
        }
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
