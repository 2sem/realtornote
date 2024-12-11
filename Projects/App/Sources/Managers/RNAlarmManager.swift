//
//  RNAlarmManager.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/29.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit
import RxSwift

class RNAlarmManager : NSObject{
//    let maxActivatedHelpers = 5;
    
    static let shared : RNAlarmManager = .init();
    public let alarms: BehaviorSubject<[RNAlarmModel]> = .init(value: []);
    var currentAlarms: [RNAlarmModel]? {
        return try? self.alarms.value();
    }
    
    public let isLoading: PublishSubject<Bool> = .init();
    
    typealias RNAlarmManagerAlarmsCompletion = (Error?, [RNAlarmModel]) -> Void;
    typealias RNAlarmManagerAlarmCompletion = (Error?, RNAlarmModel) -> Void;
    
    var modelController : RNModelController{
        return RNModelController.shared;
    }
    
    func sync(){
        self.isLoading.onNext(true);
        //create default alarm
        if !LSDefaults.alarmInitialized{
            let time = Calendar.current.dateComponents([.hour, .minute, .second], from: .now);
//            let defaultAlarm = self.modelController?.createAlarm(id: 0, weekdays: 0, time: 0, enabled: false);
//            defaultAlarm?.alarmWeekDays = DateComponents.DateWeekDay.All;
//            defaultAlarm?.alarmTime = dates;
            _ = self.create(weekDays: DateComponents.DateWeekDay.All, time: time);
            self.modelController.saveChanges();
            
            LSDefaults.alarmInitialized = true;
        }
        
        self.clear(completion: { [weak self](result) in
            guard case .success( _) = result else{
//                completion(error, models);
                self?.isLoading.onNext(false);
                return;
            }
            
            let models = self?.modelController.loadAlarms() ?? [];
            
//            RNModelController.shared.saveChanges();
            self?.applyNotifications(models, completion: { [weak self](error, alarms) in
                if let error = error{
//                    completion(nil, alarms);
                    self?.alarms.onError(error);
                    self?.isLoading.onNext(false);
                    return;
                }
//                completion(error, alarms);
                self?.isLoading.onNext(false);
                self?.alarms.onNext(alarms);
            });
        });
    }
    
    func applyNotifications(_ alarms: [RNAlarmModel], completion: @escaping RNAlarmManagerAlarmsCompletion){
        let notifications = alarms.filter{ $0.enabled }.map{ $0.toNotification() };
        LSUserNotificationManager.shared.clear(options: [.alert, .sound], idPrefix: RNAlarmModel.notificationId, completion: { (result, error) in
            guard error == nil else{
                completion(nil, alarms);
                return;
            }
            
            LSUserNotificationManager.shared.register(notifications: notifications);
            completion(error, alarms);
        })
    }
    
    func clear(completion: @escaping (Result<Bool, Error>) -> Void){
        LSUserNotificationManager.shared.clear(options: [.alert, .sound], idPrefix: RNAlarmModel.notificationId, completion: { (result, error) in
            if let error = error{
                completion(.failure(error));
            }else{
                completion(.success(result))
            }
        })
    }
    
    @discardableResult
    func create(weekDays: DateComponents.DateWeekDay, time: DateComponents, enabled: Bool = false) -> RNAlarmModel{
//        let dates = Calendar.current.dateComponents([.hour, .minute, .second], from: .now);
        let value = self.modelController.createAlarm(id: 0, weekdays: 0, time: 0, enabled: false);
        value.alarmWeekDays = weekDays;
        value.alarmTime = time;
        value.enabled = enabled;
        if enabled{
            self.register(value);
        }
        var values = (try? self.alarms.value()) ?? [];
        values.append(value);
        self.alarms.onNext(values);
        
        return value;
    }
    
    func register(_ alarm : RNAlarmModel){
        let notifications = [alarm.toNotification()];
        LSUserNotificationManager.shared.unregister(notifications: notifications) { (result, notis, error) in
            guard error == nil else{
                return;
            }
            
            if alarm.enabled{
                LSUserNotificationManager.shared.register(notifications: notifications);
            }
        }
    }
    
    func canActivate() -> Bool{
//        let activatedHelpers = self.currentAlarms?.filter{ $0.enabled }.count ?? 0;
//        guard activatedHelpers < self.maxActivatedHelpers else{
//            return false;
//        }
        
        return true;
    }
    
    func update(_ alarm : RNAlarmModel, weekday: DateComponents.DateWeekDay, time: DateComponents, completion: @escaping RNAlarmManagerAlarmCompletion){
//        let all = DateComponents.DateWeekDay.allWeekDays;
//        let weeksString = weekday.days.compactMap{ all.firstIndex(of: $0) }.map{ $0.description };
//        let hour = time.hour ?? 0;
//        let min = time.minute ?? 0;
//        let alarmTime = String(format: "%02d:%02d", hour, min).toDate("HH:mm") ?? Date();
        
        alarm.alarmWeekDays = weekday;
        alarm.alarmTime = time;
        
        RNModelController.shared.saveChanges();
        self.register(alarm);
        completion(nil, alarm);
    }
    
    func remove(_ alarm : RNAlarmModel, dispatchGroup : DispatchGroup? = nil, completion: @escaping RNAlarmManagerAlarmCompletion){
        DispatchQueue.main.async{ [weak self] in
            LSUserNotificationManager.shared.unregister(notifications: [alarm.toNotification()], completion: nil)
            
            //notify new items without removed alarm
            if let values = self?.currentAlarms {
                self?.alarms.onNext(values.filter{ alarm !== $0 });
            }
            
            self?.modelController.remove(alarm: alarm);
            self?.modelController.saveChanges();
            completion(nil, alarm);
        }
    }
    
    func disable(_ alarm : RNAlarmModel, completion: RNAlarmManagerAlarmCompletion? = nil){
        alarm.enabled = false;
        DispatchQueue.main.async {
            RNModelController.shared.saveChanges();
            LSUserNotificationManager.shared.unregister(notifications: [alarm.toNotification()], completion: nil);
//            SWToast.hideActivity();
            completion?(nil, alarm);
        }
    }
    
    func enable(_ alarm : RNAlarmModel, completion: RNAlarmManagerAlarmCompletion? = nil){
        alarm.enabled = true;
        DispatchQueue.main.async {
            RNModelController.shared.saveChanges();
            LSUserNotificationManager.shared.register(notifications: [alarm.toNotification()], completion: nil);
//            SWToast.hideActivity();
            completion?(nil, alarm);
        }
    }
}
