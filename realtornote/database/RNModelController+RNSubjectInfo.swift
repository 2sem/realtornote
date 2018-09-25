//
//  RNModelController+RNSubjectInfo.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreData

extension RNModelController{
    func loadSubjects(predicate : NSPredicate? = nil, sortWays: [NSSortDescriptor]? = [], completion: (([RNSubjectInfo], NSError?) -> Void)? = nil) -> [RNSubjectInfo]{
        //        self.waitInit();
        print("begin to load from \(self.classForCoder)");
        var values : [RNSubjectInfo] = [];
        
        let requester = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.RNSubjectInfo);
        requester.predicate = predicate;
        requester.sortDescriptors = sortWays;
        
        //        requester.predicate = NSPredicate(format: "name == %@", "Local");
        
        do{
            values = try self.context.fetch(requester) as! [RNSubjectInfo];
            print("fetch groups with predicate[\(predicate?.description ?? "")] count[\(values.count.description)]");
            /*values.forEach({ (group) in
             print("group name[\(group.name)] num[\(group.no)]");
             })*/
            completion?(values, nil);
        } catch{
            fatalError("Can not load groups from DB");
        }
        
        return values;
    }
    
    func isExistSubject(_ no : Int) -> Bool{
        let predicate = NSPredicate(format: "#no == \"\(no)\"");
        return !self.loadSubjects(predicate: predicate, sortWays: nil).isEmpty;
    }
    
    func findSubject(_ no : Int) -> RNSubjectInfo?{
        //var predicate = NSPredicate(format: "no == %i",  no);
        //var predicate = NSPredicate(format: "no == %@",  "\(no)");
        //var predicate = NSPredicate(format: "no == %@",  no.description);
        //var predicate = NSPredicate(format: "\(RNModelController.EntityNames.DAGroupInfo).no == \(no)");
        //var predicate = NSPredicate(format: "%K == \(no)",  "no");
        let predicate = NSPredicate(format: "#no == \(no)");
        //var predicate = NSPredicate(format: "name == %@",  "자유한국당");
        return self.loadSubjects(predicate: predicate, sortWays: nil).first;
    }
    
    func loadSubjects(_ isAscending : Bool = true, name : String = "") -> [RNSubjectInfo]{
        var _ : [Int : RNSubjectInfo] = [:];
        
        let predicate : NSPredicate! = NSPredicate(format: "name == %@", name);
        
        return self.loadSubjects(predicate: predicate, sortWays: [NSSortDescriptor.init(key: "name", ascending: isAscending)], completion: nil);
    }
    
    func createSubject(no: Int, name : String, detail: String = "") -> RNSubjectInfo{
        let value = NSEntityDescription.insertNewObject(forEntityName: EntityNames.RNSubjectInfo, into: self.context) as! RNSubjectInfo;
        
        value.no = Int16(no);
        value.name = name;
        value.detail = detail;
        
        print("create new subject. no[\(no)] name[\(name)]");
        
        return value;
    }
    
    func removeSubject(_ subject: RNSubjectInfo){
        self.context.delete(subject);
    }
    
    func refresh(subject: RNSubjectInfo){
        self.context.refresh(subject, mergeChanges: false);
    }    
}

