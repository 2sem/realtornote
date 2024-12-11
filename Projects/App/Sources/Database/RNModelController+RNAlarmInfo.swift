//
//  RNModelController+RNAlarmInfo.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/29.
//  Copyright © 2020 leesam. All rights reserved.
//

import Foundation
import CoreData

extension RNModelController{
    func loadAlarms(predicate : NSPredicate? = nil, sortWays: [NSSortDescriptor]? = [], completion: (([RNAlarmModel], NSError?) -> Void)? = nil) -> [RNAlarmModel]{
        //        self.waitInit();
        print("begin to load alarms from \(self.classForCoder)");
        var values : [RNAlarmModel] = [];
        
        let requester = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.alarm);
        requester.predicate = predicate;
        requester.sortDescriptors = sortWays;
        
        //        requester.predicate = NSPredicate(format: "name == %@", "Local");
        
        do{
            values = try self.context.fetch(requester) as! [RNAlarmModel];
            print("fetch alarms with predicate[\(predicate?.description ?? "")] count[\(values.count)]");
            /*values.forEach({ (person) in
             print("person no[\(person.no)] name[\(person.name)]");
             })*/
            completion?(values, nil);
        } catch let error{
            fatalError("Can not load persons from DB. error[\(error.localizedDescription)]");
        }
        
        return values;
    }
    
    func isExistStudyHelper(_ id : Int) -> Bool{
        let predicate = NSPredicate(format: "#id == \(id)");
        return !self.loadAlarms(predicate: predicate, sortWays: nil).isEmpty;
    }
    
    func findStudyHelper(_ id : Int) -> RNAlarmModel?{
        let predicate = NSPredicate(format: "#id == \(id)");
        return self.loadAlarms(predicate: predicate, sortWays: nil).first;
    }
    
    var lastAlarmId : Int64{
        var value : Int64 = 0;
        let requester = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.alarm);
        //requester.predicate = predicate;
        requester.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)];
        requester.fetchLimit = 1;
        //        requester.predicate = NSPredicate(format: "name == %@", "Local");
        
        do{
            let values = try self.context.fetch(requester) as! [RNAlarmModel];
            /*values.forEach({ (person) in
             print("person no[\(person.no)] name[\(person.name)]");
             })*/
            value = values.first?.id ?? 0;
            print("fetch last study heloper. last  id[\(value)]");
        } catch let error{
            fatalError("Can not load last study helper id from DB. error[\(error)]");
        }
        
        return value;
    }
    
    @discardableResult
    func createAlarm(id: Int64? = nil, weekdays : Int, time: Int, enabled: Bool = false) -> RNAlarmModel{
        let value = NSEntityDescription.insertNewObject(forEntityName: EntityNames.alarm, into: self.context) as! RNAlarmModel;
        
        if let id = id{
            value.id = id;
        }else{
            value.id = self.lastAlarmId + 1;
        }
        
        value.title = ["공인중개사 공부하실 시간입니다.", "오늘도 공인중개사 화이팅!", "요약집으로 공인중개사 합격!", "쉿! 나만 아는 비밀 요약집으로 공부할 시간이에요.", ""].random;
        value.time = Int64(time);
        value.weekdays = Int16(weekdays);
        value.enabled = enabled;
        
        return value;
    }
    
    func remove(alarm: RNAlarmModel){
        self.context.delete(alarm);
    }
}
