//
//  RNModelController+RNExcelController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 25..
//  Copyright © 2017년 leesam. All rights reserved.
//

import Foundation
import CoreData

extension RNModelController{
    func sync(_ excel : RNExcelController){
        print("[start] sync excel Subjects to database");
        
        self.syncSubjects(excel);
        
        RNModelController.shared.saveChanges();
        RNDefaults.DataVersion = excel.version;
        print("[end] sync excel to database");
    }
    
    func syncSubjects(_ excel : RNExcelController, controller: RNModelController = RNModelController.shared){
        print("[start] sync excel subjects to database");
        var excelSubjects = RNExcelController.Default.subjects;
        for excelSubject in excelSubjects{
            //load subjects from database
            //check if the Subject is already exist in database
            var modelSubject : RNSubjectInfo! = RNModelController.shared.findSubject(excelSubject.id);
            if modelSubject == nil{
                //create new Subject
                modelSubject = RNModelController.shared.createSubject(no: excelSubject.id, name: excelSubject.name, detail: excelSubject.detail);
            }else{
                //update new Subject
                modelSubject.name = excelSubject.name;
                modelSubject.detail = excelSubject.detail;
                print("update Subject. no[\(modelSubject.no)] name[\(modelSubject.name)]");
            }
        
            modelSubject.syncChapters(excelSubject, controller: controller);
        }
        
        print("[end] sync excel subjects to database");
    }
}
