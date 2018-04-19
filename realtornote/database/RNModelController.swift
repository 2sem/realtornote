//
//  RNModelController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreData

class RNModelController : NSObject{
    struct EntityNames{
        static let RNSubjectInfo = "RNSubjectInfo";
        static let RNChapterInfo = "RNChapterInfo";
        static let RNPartInfo = "RNPartInfo";
        static let RNFavoriteInfo = "RNFavoriteInfo";
    }
    
    static let ModelName = "realtornote";
    static let FileName = "realtornote";
    
    internal static let dispatchGroupForInit = DispatchGroup();
    //    var SingletonQ = DispatchQueue(label: "RNModelController.Default");
    private static var _shared = RNModelController();
    static var shared : RNModelController{
        get{
            let timeout = DispatchTime.now() + DispatchTimeInterval.seconds(3);
            //print("enter \(self) instance - \(self) - \(Thread.current)");
            let value = _shared;
            //            value.waitInit();
            //print("wait \(self) instance - \(self) - \(Thread.current)");
            self.dispatchGroupForInit.wait();
            //print("exit \(self) instance - \(self) - \(Thread.current)");
            
            return value;
        }
    }
    
    var context : NSManagedObjectContext;
    internal override init(){
        //lock on
        //        objc_sync_enter(RNModelController.self)
        //        print("begin init RNModelController - \(RNModelController.self) - \(Thread.current)");
        //get path for model file
        //load model scheme - xcdatamodel => momd??
        guard let model_path = Bundle.main.url(forResource: RNModelController.ModelName, withExtension: "momd") else{
            fatalError("Can not find Model File from Bundle");
        }
        
        //load model from model file
        guard let model = NSManagedObjectModel(contentsOf: model_path) else {
            fatalError("Can not load Model from File");
        }
        
        //create store controller??
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model);
        
        //create data context
        self.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType);
        //set store controller??
        self.context.persistentStoreCoordinator = psc;
        //lazy load??
        //        var queue = DispatchQueue(label: "RNModelController.init", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil);
        DispatchQueue.global(qos: .background).async(group: RNModelController.dispatchGroupForInit) {
            print("begin init RNModelController");
            //        DispatchQueue.main.async{
            
            //get path for app's url
            let storeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.appendingPathComponent(RNModelController.FileName).appendingPathExtension("sqlite");
            //create path for data file
            //let storeUrl = Bundle.main.url(forResource: RNModelController.FileName, withExtension: "sqlite");
            //let storeUrl = docUrl;
            
            do {
                //set store type?
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]);
            } catch {
                
            }
            
            //lock off
            //            objc_sync_exit(RSModelController.self);
            //RSModelController.dispatchGroupForInit.leave();
            print("end init RSModelController");
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func waitInit(){
        //        dispatchPrecondition(condition: .notOnQueue(<#T##DispatchQueue#>))
        while self.context.persistentStoreCoordinator?.persistentStores.isEmpty ?? false{
            sleep(1);
        }
    }
    
    func reset(){
        self.context.reset();
    }
    
    var isSaved : Bool{
        return !self.context.hasChanges;
    }
    
    func saveChanges(){
        do{
            try self.context.save();
        } catch {
            fatalError("Save failed Error(\(error))");
        }
    }
    
    /// MARK : support transaction
    func beginTransaction(transactionName name : String){
        if self.context.undoManager == nil {
            self.context.undoManager = UndoManager();
        }
        
        print("begin transaction. name[\(name)] context[\(self.context)]");
        self.context.undoManager?.beginUndoGrouping();
        self.context.undoManager?.setActionName(name);
    }
    
    func endTransaction(){
        print("end transaction. name[\(self.context.undoManager?.undoActionName ?? "")] context[\(self.context.description)]");
        self.context.undoManager?.endUndoGrouping();
    }
    
    func undo(){
        print("undo. name[\(self.context.undoManager?.undoActionName ?? "")] context[\(self.context.description)]");
        self.context.undoManager?.undo();
    }
    
    func rollback(){
        print("rollback. context[\(self.context)]");
        self.context.rollback();
    }
}
