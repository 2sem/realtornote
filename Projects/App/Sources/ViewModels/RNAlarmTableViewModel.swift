//
//  RNAlarmTableViewModel.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/29.
//  Copyright © 2020 leesam. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class RNAlarmTableViewModel{
    var isLoading : PublishSubject<Bool> = .init();
    var alarms : BehaviorSubject<[RNAlarmModel]> = .init(value: []);
    
    var modelController : RNModelController = .shared;
    var disposeBag : DisposeBag = .init();
    
    init() {
        self.setupBindings();
    }
    
    private func setupBindings(){
        RNAlarmManager.shared.isLoading
//            .observeOn(MainScheduler.instance)
            .bind(to: self.isLoading)
            .disposed(by: self.disposeBag)
        
        RNAlarmManager.shared.alarms
            .bind(to: self.alarms)
            .disposed(by: self.disposeBag)
    }
    
    func load(){
        //RNAlarmManager.shared.
    }
    
    func create(weekDays: DateComponents.DateWeekDay, time: DateComponents) -> RNAlarmModel{
//        let dates = Calendar.current.dateComponents([.hour, .minute, .second], from: .now);
        return RNAlarmManager.shared.create(weekDays: weekDays, time: time);
    }
    
    func remove(_ alarm : RNAlarmModel, completion: @escaping RNAlarmManager.RNAlarmManagerAlarmCompletion){
        RNAlarmManager.shared.remove(alarm, completion: completion);
    }
}
