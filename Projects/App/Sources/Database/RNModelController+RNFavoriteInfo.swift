//
//  RNModelController+RNFavoriteInfo.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 30..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreData

extension RNModelController{
    func loadFavorites(predicate : NSPredicate? = nil, sortWays: [NSSortDescriptor]? = [], completion: (([RNFavoriteInfo], NSError?) -> Void)? = nil, onlyOne : Bool = false) -> [RNFavoriteInfo]{
        //        self.waitInit();
        print("begin to load from \(self.classForCoder)");
        var values : [RNFavoriteInfo] = [];
        
        let requester = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.RNFavoriteInfo);
        requester.predicate = predicate;
        requester.sortDescriptors = sortWays;
        if onlyOne{
            requester.fetchLimit = 1;
        }
        
        //        requester.predicate = NSPredicate(format: "name == %@", "Local");
        
        do{
            values = try self.context.fetch(requester) as! [RNFavoriteInfo];
            print("fetch persons with predicate[\(predicate?.description ?? "")] count[\(values.count.description)]");
            completion?(values, nil);
        } catch{
            fatalError("Can not load persons from DB");
        }
        
        return values;
    }
    
    func loadFavoritesByNo() -> [RNFavoriteInfo]{
        //var values : [RNFavoriteInfo] = [];
        _ = 0;
        
        let favorites = self.loadFavorites(predicate: nil, sortWays: [NSSortDescriptor.init(key: "no", ascending: true)], completion: nil);
        
        return favorites;
    }
    
    func loadFavoritesBySubjectNo() -> [RNFavoriteInfo]{
        //var values : [RNFavoriteInfo] = [];
        _ = 0;
        
        let favorites = self.loadFavorites(predicate: nil, sortWays: [NSSortDescriptor.init(key: "part.chapter.subject.no", ascending: true), NSSortDescriptor.init(key: "part.chapter.no", ascending: true), NSSortDescriptor.init(key: "part.no", ascending: true)], completion: nil);
        
        return favorites;
    }
    
    func isExistFavorite(_ part : RNPartInfo) -> Bool{
        let predicate = NSPredicate(format: "part == %@", part.objectID);
        return !self.loadFavorites(predicate: predicate, sortWays: nil, onlyOne: true).isEmpty;
    }
    
    func findFavorite(_ part : RNPartInfo) -> RNFavoriteInfo?{
        let predicate = NSPredicate(format: "part == %@", part.objectID);
        return self.loadFavorites(predicate: predicate, sortWays: nil, onlyOne: true).first;
    }
    
    func maxFavoriteNo() -> Int32{
        let favorites = self.loadFavorites(predicate: nil, sortWays: [NSSortDescriptor.init(key: "no", ascending: false)], completion: nil, onlyOne: true);
        
        return favorites.first?.no ?? 0;
    }

    @discardableResult
    func createFavorite(_ part : RNPartInfo) -> RNFavoriteInfo{
        let favorite = NSEntityDescription.insertNewObject(forEntityName: EntityNames.RNFavoriteInfo, into: self.context) as! RNFavoriteInfo;
        
        favorite.part = part;
        favorite.no = self.maxFavoriteNo() + 1;
        
        return favorite;
    }
    
    func removeFavorite(_ favorite: RNFavoriteInfo){
        self.context.delete(favorite);
    }
    
    func refresh(favorite: RNFavoriteInfo){
        self.context.refresh(favorite, mergeChanges: false);
    }
}
