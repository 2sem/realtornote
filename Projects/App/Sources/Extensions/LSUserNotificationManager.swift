//
//  LSUserNotificationManager.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/17.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit
import UserNotifications

@available(iOS 10.0, *)
class LSUserNotificationManager : NSObject, UNUserNotificationCenterDelegate{
    static let shared = LSUserNotificationManager();
    private var notifications : [String : LSUserNotification] = [:];
    
    private var categories : [String:UNNotificationCategory] = [:];
    //private var actions : [String : ]
    override init(){
        super.init()
        //UNUserNotificationCenter.current().delegate = self;
    }
    
    func getNotification(_ identifier : String) -> LSUserNotification?{
        //var test : UILocalNotification!;
        
        return self.notifications[identifier];
    }
    
    func clear(options : UNAuthorizationOptions = [.alert, .sound], idPrefix: String = "", completion: ((Bool, Error?) -> Void)? = nil){
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (authorized, error) in
            guard authorized else {
                print("you have no permission to remove all notifications. error[\(error?.localizedDescription ?? "")]");
                completion?(false, error);
                return;
            }
            
            if idPrefix.isEmpty{
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests();
                completion?(true, nil);
                
            }else{
                UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { (notifications) in
                    let noti_ids = notifications.filter({ (noti) -> Bool in
                        return noti.request.identifier.hasPrefix(idPrefix);
                    }).map({ (noti) -> String in
                        return noti.request.identifier
                    });
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: noti_ids);
                    print("remove delivered alarms[\(noti_ids)]");
                    UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                        let noti_ids = requests.filter({ (req) -> Bool in
                            return req.identifier.hasPrefix(idPrefix);//
                        }).map({ (req) -> String in
                            return req.identifier;
                        })
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: noti_ids);
                        print("remove pending alarms[\(noti_ids)]");
                        completion?(true, nil);
                    })
                })
            }
        }
    }
    
    func register(options : UNAuthorizationOptions = [.alert, .sound], notifications : [LSUserNotification], completion: ((Bool, [LSUserNotification], Error?) -> Void)? = nil){
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (authorized, error) in
            guard authorized else {
                print("you have no permission to register notification. error[\(error?.localizedDescription ?? "")]");
                //completion?(notifications, error);
                completion?(false, notifications, error);
                return;
            }
            
            notifications.forEach({ (notification) in
                guard self.categories[notification.identifier] == nil else{
                    return;
                }
                
                //create new category
                let category = UNNotificationCategory(identifier: notification.identifier,
                                                      actions: notification.actions.map({ (act) -> UNNotificationAction in
                                                        notification.actions.append(act);
                                                        return UNNotificationAction(identifier: act.identifier, title: act.title, options: act.options)
                                                      }), intentIdentifiers: [], options: .customDismissAction);
                self.categories[notification.identifier] = category;
            })
            
            UNUserNotificationCenter.current().setNotificationCategories(Set(self.categories.values));
            
            var notiRegErrors : [Error] = []
            notifications.forEach({ (notification) in
                guard notiRegErrors.isEmpty else{
                    return;
                }
                
                let content = UNMutableNotificationContent();
                content.title = notification.title;
                content.body = notification.body;
                //link notification to category
                content.categoryIdentifier = notification.identifier;
                //set sound when notification triggered
                content.sound = notification.sound;
                content.userInfo = notification.userInfo;
                //play default sound if can't find the named sound file
                //content.sound = UNNotificationSound.init(named: "resource name"); //aiff
                
                //var existNotificationIdentifiers : [String] = [];
                let category = self.categories[notification.identifier];
                /*self.findNotifications(category: category!, completionHandler: { (notifications) in
                 existNotificationIdentifiers.append(contentsOf: notifications.map({ (noti) -> String in
                 return noti.request.identifier;
                 }))
                 })*/
                let days : [DateComponents.DateWeekDay?] = notification.weekdays?.days.map({ (day) -> DateComponents.DateWeekDay? in
                    return day;
                }) ?? [nil];
                //let results : [Bool] = [];
                days.forEach({ (day) in
                    var timeInfo = notification.dateComponent;
                    if day != nil{
                        timeInfo.weekDay = day;
                    }else{
                        timeInfo = Calendar.current.dateComponents([.day,.minute,.hour, .month,.year,.second], from: timeInfo.date!);
                        //timeInfo.day = notification.dateComponent.day;
                        //timeInfo.second = 30;
                    }
                    
                    let trigger = UNCalendarNotificationTrigger.init(dateMatching: timeInfo, repeats: !notification.once);
                    let noti_id = category!.identifier + (day != nil ? day!.string : "");
                    /*guard !existNotificationIdentifiers.contains(noti_id) else{
                     return;
                     }*/
                    
                    let req = UNNotificationRequest.init(identifier: noti_id, content: content, trigger: trigger);
                    
                    //register notification
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [noti_id]);
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [noti_id]);
                    UNUserNotificationCenter.current().add(req, withCompletionHandler: { (error) in
                        print("add notification identifier[\(req.identifier)] title[\(content.title)] body[\(content.body)] time[\(timeInfo.year ?? 0)-\(timeInfo.month ?? 0)-\(timeInfo.day ?? 0) \(timeInfo.hour ?? 0):\(timeInfo.minute ?? 0):\(timeInfo.second ?? 0)] day[\(timeInfo.weekday?.description ?? "")] date[\(timeInfo.date?.toString() ?? "")] once[\(notification.once)] error[\(error?.localizedDescription ?? "")]");
                        guard error == nil else{
                            print("notification add error[\(error.debugDescription)]");
                            //completion?(nil, error);
                            notiRegErrors.append(error!);
                            return;
                        }
                        
                        //completion?(nil, error);
                    })
                })
                
                self.notifications[notification.identifier] = notification;
            })
            
            completion?(notiRegErrors.isEmpty, notifications, notiRegErrors.first);
        }
    }
    
    func register(options : UNAuthorizationOptions = [.alert, .sound], identifier: String, title: String, body: String = "", sound : UNNotificationSound = UNNotificationSound.default, dateComponent: DateComponents, weekdays: DateComponents.DateWeekDay? = nil, repeating: Bool = false, enabled : Bool = false, actions : [LSUserNotificationAction] = [], handler: LSUserNotification.LSUserNotificationHandler? = nil, completion: ((LSUserNotification?, Error?) -> Void)?){
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (authorized, error) in
            guard authorized else {
                print("you have no permission to register notification. error[\(error.debugDescription)]");
                completion?(nil, error);
                return;
            }
            
            let notification = LSUserNotification();
            notification.actions = actions;
            notification.handler = handler;
            
            var category : UNNotificationCategory! = self.categories[identifier];
            
            //create new category
            if category == nil{
                category = UNNotificationCategory(identifier: identifier,
                                                  actions: actions.map({ (act) -> UNNotificationAction in
                                                    notification.actions.append(act);
                                                    return UNNotificationAction(identifier: act.identifier, title: act.title, options: act.options)
                                                  }), intentIdentifiers: [], options: .customDismissAction);
                self.categories[identifier] = category;
            }
            
            UNUserNotificationCenter.current().setNotificationCategories(Set(self.categories.values));
            
            let content = UNMutableNotificationContent();
            content.title = title;
            content.body = body;
            //link notification to category
            content.categoryIdentifier = category.identifier;
            //set sound when notification triggered
            content.sound = sound;
            //play default sound if can't find the named sound file
            //content.sound = UNNotificationSound.init(named: "resource name"); //aiff
            
            var existNotificationIdentifiers : [String] = [];
            self.findNotifications(category: category, completionHandler: { (notifications) in
                existNotificationIdentifiers.append(contentsOf: notifications.map({ (noti) -> String in
                    return noti.request.identifier;
                }))
            })
            let days : [DateComponents.DateWeekDay?] = weekdays?.days.map({ (day) -> DateComponents.DateWeekDay? in
                return day;
            }) ?? [nil];
            days.forEach({ (day) in
                var timeInfo = dateComponent;
                timeInfo.weekDay = day;
                
                let trigger = UNCalendarNotificationTrigger.init(dateMatching: timeInfo, repeats: true);
                let noti_id = category.identifier + (day != nil ? day!.string : "");
                guard !existNotificationIdentifiers.contains(noti_id) else{
                    return;
                }
                
                let req = UNNotificationRequest.init(identifier: noti_id, content: content, trigger: trigger);
                
                //register notification
                UNUserNotificationCenter.current().add(req, withCompletionHandler: { (error) in
                    print("add notification identifier[\(req.identifier)] title[\(content.title)] body[\(content.body)]");
                    guard error != nil else{
                        //completion?(nil, error);
                        return;
                    }
                    
                    print("notification add error[\(error.debugDescription)]");
                    //completion?(nil, error);
                })
            })
            
            notification.identifier = identifier;
            notification.title = title;
            
            notification.body = body;
            notification.sound = sound;
            notification.dateComponent = dateComponent;
            notification.weekdays = weekdays;
            notification.once = !repeating;
            
            
            self.notifications[identifier] = notification;
            completion?(notification, error);
        }
    }
    
    func removeDay(notification: LSUserNotification, day: DateComponents.DateWeekDay, completion: ((Bool, LSUserNotification, DateComponents.DateWeekDay, Error?) -> Void)? = nil){
        UNUserNotificationCenter.current().requestAuthorization(options: UNAuthorizationOptions.init(rawValue: 0)) { (authorized, error) in
            guard authorized else {
                print("you have no permission to register notification. error[\(error.debugDescription)]");
                completion?(false, notification, day, error);
                return;
            }
            
            let noti_id = notification.identifier + day.string;
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [noti_id]);
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [noti_id]);
            print("remove notification identifier[\(noti_id)] title[\(notification.title)] body[\(notification.body)]");
            completion?(true, notification, day, nil);
        }
    }
    
    func insertDay(notification: LSUserNotification, day: DateComponents.DateWeekDay, completion: ((Bool, LSUserNotification, DateComponents.DateWeekDay, Error?) -> Void)? = nil){
        UNUserNotificationCenter.current().requestAuthorization(options: UNAuthorizationOptions.init(rawValue: 0)) { (authorized, error) in
            guard authorized else {
                print("you have no permission to register notification. error[\(error.debugDescription)]");
                completion?(false, notification, day, error);
                return;
            }
            
            let content = UNMutableNotificationContent();
            content.title = notification.title;
            content.body = notification.body;
            //link notification to category
            content.categoryIdentifier = notification.identifier;
            //set sound when notification triggered
            content.sound = notification.sound;
            content.userInfo = notification.userInfo;
            
            let noti_id = notification.identifier + day.string;
            var timeInfo = notification.dateComponent;
            timeInfo.weekDay = day;
            
            let trigger = UNCalendarNotificationTrigger.init(dateMatching: timeInfo, repeats: !notification.once);
            
            let req = UNNotificationRequest.init(identifier: noti_id, content: content, trigger: trigger);
            
            //register notification
            UNUserNotificationCenter.current().add(req, withCompletionHandler: { (error) in
                print("add notification identifier[\(req.identifier)] title[\(content.title)] body[\(content.body)] time[\(timeInfo.hour ?? 0):\(timeInfo.minute ?? 0)]");
                guard error != nil else{
                    print("notification add error[\(error.debugDescription)]");
                    //completion?(nil, error);
                    return;
                }
                
                //completion?(nil, error);
            })
            
            completion?(true, notification, day, nil);
        }
    }
    
    func updateTime(notification: LSUserNotification, dateComponent : DateComponents, completion: ((Bool, LSUserNotification, DateComponents, Error?) -> Void)? = nil){
        
        
        UNUserNotificationCenter.current().requestAuthorization(options: UNAuthorizationOptions.init(rawValue: 0)) { (authorized, error) in
            guard authorized else {
                print("you have no permission to register notification. error[\(error.debugDescription)]");
                completion?(false, notification, dateComponent, error);
                return;
            }
            
            var identifiers : [String] = [];
            
            notification.weekdays?.days.forEach({ (day) in
                let id = notification.identifier + day.string;
                identifiers.append(id);
            })
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers);
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers);
            print("remove notification identifiers[\(identifiers)] title[\(notification.title)] body[\(notification.body)]");
            
            notification.dateComponent = dateComponent;
            self.register(options: [.alert, .sound], notifications: [notification], completion: { (result, notifications, error) in
                completion?(result, notification, dateComponent, error);
            })
        }
    }
    
    func loadNotifications(){
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            for req in requests{
                let trigger = req.trigger as? UNCalendarNotificationTrigger;
                print("pending noti. id[\(req.identifier)] category[\(req.content.categoryIdentifier)] title[\(req.content.title)] trigger[date(\(trigger?.dateComponents.date?.description ?? ""))-weekday(\(trigger?.dateComponents.weekday?.description ?? ""))]");
            }
        }
    }
    
    func findNotifications(category: UNNotificationCategory, completionHandler: @escaping ([UNNotification]) -> Void){
        //UNUserNotificationCenter.current().g
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { (notifications) in
            completionHandler(notifications.filter({ (notification) -> Bool in
                return notification.request.content.categoryIdentifier == category.identifier;
            }));
        })
    }
    
    func unregister(notifications : [LSUserNotification], completion: ((Bool, [LSUserNotification], Error?) -> Void)? = nil){
        UNUserNotificationCenter.current().requestAuthorization(options: UNAuthorizationOptions.init(rawValue: 0)) { (authorized, error) in
            guard authorized else {
                print("you have no permission to unregister notification. error[\(error.debugDescription)]");
                //completion?(notifications, error);
                completion?(false, notifications, error);
                return;
            }
            
            notifications.forEach({ (notification) in
                guard self.categories[notification.identifier] != nil else{
                    return;
                }
                
                self.categories[notification.identifier] = nil;
            })
            
            UNUserNotificationCenter.current().setNotificationCategories(Set(self.categories.values));
            
            notifications.forEach({ (notification) in
                /*var existNotificationIdentifiers : [String] = [];
                 var category = self.categories[notification.identifier];
                 self.findNotifications(category: category!, completionHandler: { (notifications) in
                 existNotificationIdentifiers.append(contentsOf: notifications.map({ (noti) -> String in
                 return noti.request.identifier;
                 }))
                 })*/
                
                var identifiers : [String] = [];
                let days : [DateComponents.DateWeekDay?] = notification.weekdays?.days.map({ (day) -> DateComponents.DateWeekDay? in
                    return day;
                }) ?? [nil];
                days.forEach({ (day) in
                    var timeInfo = notification.dateComponent;
                    timeInfo.weekDay = day;
                    
                    //let trigger = UNCalendarNotificationTrigger.init(dateMatching: timeInfo, repeats: true);
                    let identifier = notification.identifier + (day != nil ? day!.string : "");
                    identifiers.append(identifier);
                    print("remove notification identifier[\(identifier)] title[\(notification.title)] body[\(notification.body)] time[\(timeInfo.hour ?? 0):\(timeInfo.minute ?? 0)]");
                })
                
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers);
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers);
                
                self.notifications[notification.identifier] = notification;
                completion?(true, notifications, error);
            })
        }
    }
    
    /// handle action button
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("receive local notification in background. action[\(response.actionIdentifier)]");
        
        let category : UNNotificationCategory! = self.categories[response.notification.request.content.categoryIdentifier];
        
        guard category != nil else{
            completionHandler();
            return;
        }
        
        let actions = self.notifications[category.identifier]?.actions;
        let action = actions?.first(where: { (act) -> Bool in
            return act.identifier == response.actionIdentifier;
        })
        
        guard action != nil else{
            completionHandler();
            return;
        }
        
        action?.handler(category, action!);
        completionHandler();
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //update app
        let id = notification.request.identifier;
        let title = notification.request.content.title;
        let body = notification.request.content.body;
        let payload = notification.request.content.userInfo;
        print("receive push notification in foreground. identifier[\(id)] title[\(title)] body[\(body)] payload[\(payload)]");
        
        //UNNotificationPresentationOptions
        completionHandler([.alert, .sound]);
    }
}

@available(iOS 10.0, *)
class LSUserNotification : NSObject{
    typealias LSUserNotificationHandler = (LSUserNotification) -> Void;
    var identifier: String = "";
    var title: String = "";
    
    //var options : UNAuthorizationOptions = [.alert, .sound]
    var body: String = "";
    var sound : UNNotificationSound = UNNotificationSound.default;
    var dateComponent: DateComponents = DateComponents();
    var weekdays: DateComponents.DateWeekDay? = nil;
    var once : Bool = false;
    var actions : [LSUserNotificationAction] = [];
    var handler : LSUserNotificationHandler?;
    var userInfo : [AnyHashable : Any] = [:];
    
    /*var title : String = "";
     var body : String = "";
     var enable : Bool = false;
     var targetTime : DateComponents = DateComponents();
     var alarmTime : Int = 0;
     var weekdays : DateComponents.DateWeekDay = DateComponents.DateWeekDay.All;
     var sound = UNNotificationSound.default();*/
}

@available(iOS 10.0, *)
class LSUserNotificationAction : NSObject{
    typealias ActionHandler = (UNNotificationCategory, LSUserNotificationAction) -> Void;
    
    var identifier : String = "";
    var title : String = "";
    var options : UNNotificationActionOptions = UNNotificationActionOptions(rawValue: 0);
    var handler : ActionHandler;
    
    init(identifier : String, title : String = "", options : UNNotificationActionOptions = UNNotificationActionOptions(rawValue: 0), handler : @escaping ActionHandler){
        self.handler = handler;
        super.init();
        self.identifier = identifier;
        
        if title.isEmpty{
            self.title = identifier;
        }else{
            self.title = title;
        }
        
        self.options = options;
    }
}
