//
//  RNModelController+RNPartInfo.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreData

extension RNModelController{
    func loadParts(predicate : NSPredicate? = nil, sortWays: [NSSortDescriptor]? = [], completion: (([RNPartInfo], NSError?) -> Void)? = nil) -> [RNPartInfo]{
        //        self.waitInit();
        print("begin to load from \(self.classForCoder)");
        var values : [RNPartInfo] = [];
        
        let requester = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.RNPartInfo);
        requester.predicate = predicate;
        requester.sortDescriptors = sortWays;
        
        //        requester.predicate = NSPredicate(format: "name == %@", "Local");
        
        do{
            values = try self.context.fetch(requester) as! [RNPartInfo];
            print("fetch groups with predicate[\(predicate?.description ?? "")] count[\(values.count)]");
            /*values.forEach({ (group) in
             print("group name[\(group.name)] num[\(group.no)]");
             })*/
            completion?(values, nil);
        } catch{
            fatalError("Can not load groups from DB");
        }
        
        return values;
    }
    
    func isExistPart(_ no : Int) -> Bool{
        let predicate = NSPredicate(format: "#no == \"\(no)\"");
        return !self.loadParts(predicate: predicate, sortWays: nil).isEmpty;
    }
    
    func findPart(_ no : Int) -> RNPartInfo?{
        //var predicate = NSPredicate(format: "no == %i",  no);
        //var predicate = NSPredicate(format: "no == %@",  "\(no)");
        //var predicate = NSPredicate(format: "no == %@",  no.description);
        //var predicate = NSPredicate(format: "\(RNModelController.EntityNames.DAGroupInfo).no == \(no)");
        //var predicate = NSPredicate(format: "%K == \(no)",  "no");
        let predicate = NSPredicate(format: "#no == \(no)");
        //var predicate = NSPredicate(format: "name == %@",  "자유한국당");
        return self.loadParts(predicate: predicate, sortWays: nil).first;
    }
    
    func loadParts(_ isAscending : Bool = true, name : String = "") -> [RNPartInfo]{
        let predicate : NSPredicate! = NSPredicate(format: "name == %@", name);
        
        return self.loadParts(predicate: predicate, sortWays: [NSSortDescriptor.init(key: "name", ascending: isAscending)], completion: nil);
    }
    
    func createPart(no: Int, seq : Int, name : String, detail: String = "") -> RNPartInfo{
        let value = NSEntityDescription.insertNewObject(forEntityName: EntityNames.RNPartInfo, into: self.context) as! RNPartInfo;
        
        value.no = Int16(no);
        value.seq = Int16(seq);
        value.name = name;
        
        print("create new subject. no[\(no)] name[\(name)]");
        
        return value;
    }
    
    func removePart(_ Part: RNPartInfo){
        self.context.delete(Part);
    }
    
    func refresh(Part: RNPartInfo){
        self.context.refresh(Part, mergeChanges: false);
    }
}
