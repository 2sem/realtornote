//
//  RNAlarmTableViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/18.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RNAlarmTableViewController: UIViewController {
    
    class Cells{
        static let `default` = "alarm";
    }
    
    var dispatchGroup = DispatchGroup();
    
    var weekDays : DateComponents.DateWeekDay = DateComponents.DateWeekDay.All;
    var time : DateComponents = DateComponents.init(hour: 0, minute: 0);
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timePicker: UIDatePicker!

    var viewModel : RNAlarmTableViewModel = .init();
    var disposeBag : DisposeBag = .init();
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.contentInset.top = 16;
        self.tableView.contentInset.bottom = 16;
        
        self.setupBindings();
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        self.timePicker.date = Calendar.current.date(from: self.time)!;
//        self.updateDayButtons();
    }
    
    func setupBindings(){
        self.viewModel.alarms
            .observe(on: MainScheduler.instance)
            .bindTableView(to: self.tableView, cellIdentifier: Cells.default, cellType: RNAlarmTableViewCell.self, disposeBag: self.disposeBag) { [weak self](index, row, cell) in
                cell.info = row;
                cell.isFirst = index == 0;
                cell.setEnableHandler { (isOn, completion) in
                    if isOn{
                        RNAlarmManager.shared.enable(row) { (error, alarm) in
                            guard error == nil else{
                                return;
                            }
                            
                            completion(true);
                        }
                    }else{
                        RNAlarmManager.shared.disable(row) { (error, alarm) in
                            guard error == nil else{
                                return;
                            }
                            
                            completion(true);
                        }
                    }
                }
                
                cell.setDeleteHandler { [weak self](cell) in
                    self?.showAlert(title: "알림 삭제", msg: "공부 알림을 삭제하시겠습니까?", actions: [.destructive("삭제", handler: { [weak self](act) in
                        guard let self = self else{
                            return;
                        }
                        
                        self.viewModel.remove(cell.info) { (error, model) in
                            guard error == nil else{
                                return;
                            }
                            
//                            self.tableView?.deleteRows(at: [IndexPath.init(row: index, section: 0)], with: .automatic);
                        }
                    }), .cancel("취소")], style: .alert);
                }
            }
    }
    
    func refresh(){
        self.viewModel.load();
    }
    
    @IBAction func onApply(_ unwindSegue: UIStoryboardSegue){
        guard let settingsView = unwindSegue.source as? LSAlarmSettingsViewController else{
            return;
        }
        
        switch settingsView.mode {
        case .create:
            RNAlarmManager.shared.create(weekDays: settingsView.weekDays, time: settingsView.time, enabled: true);
            break
        default:
            let cell : RNAlarmTableViewCell! = self.tableView.visibleCells
                .compactMap{ $0 as? RNAlarmTableViewCell }
                .filter{ $0.info.isEqual(settingsView.object) }
                .first;
            
            guard let alarm = cell.info else{
                return;
            }
            
            cell?.info.alarmWeekDays = settingsView.weekDays;
            cell?.info.alarmTime = settingsView.time;
            cell?.updateInfo();
            RNAlarmManager.shared.update(alarm, weekday: settingsView.weekDays, time: settingsView.time) { (error, model) in
                
            }
            break
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let settingsView = segue.destination as? LSAlarmSettingsViewController{
            if let cell = sender as? RNAlarmTableViewCell, let alarm = cell.info{
                settingsView.mode = .edit;
                settingsView.object = alarm;
                settingsView.weekDays = alarm.alarmWeekDays;
                settingsView.time = alarm.alarmTime;
            }else{
                settingsView.mode = .create;
                settingsView.weekDays = .init(rawValue: 0);
                settingsView.time = Calendar.current.dateComponents([.hour, .minute, .second], from: Date());
            }
            
        }
    }
    

}
