//
//  RNAlarmModel+LSUserNotification.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/29.
//  Copyright © 2020 leesam. All rights reserved.
//

import Foundation
import UserNotifications

extension RNAlarmModel{
    static let notificationId = "study alarm";
    @available(iOS 10.0, *)
    func toNotification() -> LSUserNotification{
        let notificationId = "\(type(of: self).notificationId)\(self.id)";
        var value : LSUserNotification! = UserNotificationManager.shared.getNotification(notificationId);
        
        if value == nil{
            value = LSUserNotification();
            value.identifier = notificationId;
            value.title = "공부시간알림";
            value.body = ["공인중개사 공부하실 시간입니다.", "공인중개사 공부하고 계신거죠? 오늘도 화이팅!", "요약집으로 공인중개사 합격!", "쉿! 나만 아는 비밀 요약집으로 공부할 시간이에요."].random ?? "";
            //value.sound = UNNotificationSound(named: "siwon.aiff");
            //value.sound = self.sound;
            value.once = false;
            value.userInfo = ["category" : "alarm", "subject" : self.subject?.no ?? 0];
            
            value?.handler = { (notification) in
                print("did touch notification push");
            }
        }
        
        value.dateComponent = self.alarmTime;
        value.weekdays = self.alarmWeekDays;
        
        return value;
    }
}
