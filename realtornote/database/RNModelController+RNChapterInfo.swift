//
//  RNModelController+RNChapterInfo.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreData

extension RNModelController{
    func loadChapters(predicate : NSPredicate? = nil, sortWays: [NSSortDescriptor]? = [], completion: (([RNChapterInfo], NSError?) -> Void)? = nil) -> [RNChapterInfo]{
        //        self.waitInit();
        print("begin to load from \(self.classForCoder)");
        var values : [RNChapterInfo] = [];
        
        let requester = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.RNChapterInfo);
        requester.predicate = predicate;
        requester.sortDescriptors = sortWays;
        
        //        requester.predicate = NSPredicate(format: "name == %@", "Local");
        
        do{
            values = try self.context.fetch(requester) as! [RNChapterInfo];
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
    
    func isExistChapter(_ no : Int) -> Bool{
        let predicate = NSPredicate(format: "#no == \"\(no.description)\"");
        return !self.loadChapters(predicate: predicate, sortWays: nil).isEmpty;
    }
    
    func findChapter(_ no : Int) -> RNChapterInfo?{
        //var predicate = NSPredicate(format: "no == %i",  no);
        //var predicate = NSPredicate(format: "no == %@",  "\(no)");
        //var predicate = NSPredicate(format: "no == %@",  no.description);
        //var predicate = NSPredicate(format: "\(RNModelController.EntityNames.DAGroupInfo).no == \(no)");
        //var predicate = NSPredicate(format: "%K == \(no)",  "no");
        let predicate = NSPredicate(format: "#no == \(no)");
        
        //var predicate = NSPredicate(format: "name == %@",  "자유한국당");
        return self.loadChapters(predicate: predicate, sortWays: nil).first;
    }
    
    func loadChapters(_ isAscending : Bool = true, name : String = "") -> [RNChapterInfo]{
        var _ : [Int : RNChapterInfo] = [:];
        
        let predicate : NSPredicate! = NSPredicate(format: "name == %@", name);
        
        return self.loadChapters(predicate: predicate, sortWays: [NSSortDescriptor.init(key: "name", ascending: isAscending)], completion: nil);
    }
    
    func createChapter(no: Int, seq : Int, name : String, detail: String = "") -> RNChapterInfo{
        let value = NSEntityDescription.insertNewObject(forEntityName: EntityNames.RNChapterInfo, into: self.context) as! RNChapterInfo;
        
        value.no = Int16(no);
        value.seq = Int16(seq);
        value.name = name;
        
        print("create new subject. no[\(no)] name[\(name)]");
        
        return value;
    }
    
    func removeChapter(_ chapter: RNChapterInfo){
        self.context.delete(chapter);
    }
    
    func refresh(chapter: RNChapterInfo){
        self.context.refresh(chapter, mergeChanges: false);
    }
}
