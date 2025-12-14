//
//  Alarm+.swift
//  realtornote
//
//  Created by Claude Code
//

import Foundation
import LSExtensions

extension Alarm {
    var alarmTime: DateComponents {
        get {
            let t = Date(timeInterval: TimeInterval(self.time), since: Date().zeroDate)
            return Calendar.current.dateComponents([.hour, .minute, .second], from: t)
        }
        
        set(value) {
            self.time = Int64(value.time)
        }
    }
    
    var alarmWeekDays: DateComponents.DateWeekDay {
        get {
            return DateComponents.DateWeekDay(rawValue: Int(self.weekdays))
        }
        set(value) {
            self.weekdays = Int16(value.rawValue)
        }
    }
    
    var alarmWeekDaysInts: [Int] {
        let all = DateComponents.DateWeekDay.allWeekDays
        return self.alarmWeekDays.days.compactMap { all.firstIndex(of: $0) }
    }
    
    var alarmDescription: String {
        get {
            var value = self.alarmWeekDays.string

            guard !value.isEmpty else {
                return "알리지 않음"
            }

            let date = self.alarmTime

            let hour = date.hour! > 12 ? date.hour! - 12 : date.hour!

            if value != "매일" {
                value.append("요일")
            }

            value.append(" \(date.hour == nil ? "매시" : (date.hour! >= 12 ? "오후" : "오전") + " \(hour)시")")

            if date.minute! == 0 {
                value.append(" 정각")
            } else {
                value.append(" \(date.minute!)분")
            }

            value.append(" 알림")

            return value
        }
    }

    // MARK: - Notification Support

    static let notificationId = "study alarm"

    func toNotification() -> LSUserNotification {
        let notificationId = "\(type(of: self).notificationId)\(self.id)"
        var value: LSUserNotification! = UserNotificationManager.shared.getNotification(notificationId)

        if value == nil {
            value = LSUserNotification()
            value.identifier = notificationId
            value.title = "공부시간알림"
            value.body = ["공인중개사 공부하실 시간입니다.", "공인중개사 공부하고 계신거죠? 오늘도 화이팅!", "요약집으로 공인중개사 합격!", "쉿! 나만 아는 비밀 요약집으로 공부할 시간이에요."].randomElement() ?? ""
            value.once = false
            value.userInfo = ["category": RNPushController.Category.alarm.rawValue, "subject": self.subject?.id ?? 0]

            value?.handler = { (notification) in
                print("did touch notification push")
            }
        }

        value.dateComponent = self.alarmTime
        value.weekdays = self.alarmWeekDays

        return value
    }
}

