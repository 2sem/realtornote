//
//  RNQuestionViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 8. 14..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import LSCountDownLabel
import Firebase

class RNQuestionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var questions : [RNQuestionInfo] = [];
    var question : RNQuestionInfo!;
    var index = 0;
    
    var adWindowBackup : UIWindow!;
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countDownLabel: LSCountDownLabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerTable: UITableView!
    
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var restartButton: UIBarButtonItem!

    override func viewWillAppear(_ animated: Bool) {
        GADInterstialManager.shared?.rootViewController = self;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        guard !self.questions.isEmpty else{
            self.showAlert(title: "문제생성 실패", msg: "문제 생성을 위한 데이터가 충분하지 않습니다", actions: [UIAlertAction.init(title: "확인", style: .default, handler: { (act) in
                self.dismiss(animated: false, completion: nil);
            })], style: .alert);
            return;
        }
        
        self.loadQuestion(self.index);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.setScreenName(for: self);
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        GADInterstialManager.shared?.rootViewController = nil;
    }
    
    func loadQuestion(_ index : Int){
        self.question = self.questions[index];
        self.questionLabel.text = self.question.text;
        self.titleLabel.text = self.question.title;
        self.navigationItem.title = "자동 생성 퀴즈 (\(self.index + 1)/\(self.questions.count))";
        
        self.answerTable.reloadData();
        self.answerTable.allowsSelection = true;
        
        self.countDownLabel.start { (remainSeconds) in
            let answer_idx = self.question.answers.enumerated().first(where: { (index, ans) -> Bool in
                return ans.isCorrect;
            });
            
            let cell = self.answerTable.cellForRow(at: IndexPath.init(row: answer_idx!.offset, section: 0)) as? RNQuestionTableViewCell;
            cell?.markOn();
            self.countDownLabel.text = "";
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.next();
            })
        }
    }
    
    func next(){
        self.index = self.index + 1;
        guard self.index < self.questions.count else{
            self.restartButton.isEnabled = true;
            self.answerTable.allowsSelection = false;
            Analytics.logLeesamEvent(.finishQuiz, parameters: [:]);
            if self.presentingViewController != nil && GADRewardManager.shared?.canShow ?? false{
                GADInterstialManager.shared?.show(true);
            }
            return;
        }
        self.loadQuestion(self.index);
    }
    
    @IBAction func onRestart(_ sender: UIBarButtonItem) {
        Analytics.logLeesamEvent(.restartQuiz, parameters: [:]);
        self.index = 0;
        self.loadQuestion(self.index);
        self.restartButton.isEnabled = false;
    }
    
    @IBAction func onClose(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true) { 
            
        };
    }

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.question == nil ? 0 : 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.question.answers.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RNQuestionTableViewCell", for: indexPath) as? RNQuestionTableViewCell;
        
        cell!.answer = self.question.answers[indexPath.row];
        cell!.index = indexPath.row + 1;
        
        return cell!;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //var cell = tableView.cellForRow(at: indexPath) as? RNQuestionTableViewCell;
        //cell?.answer?.isCorrect
        
        //var indexes = tableView.indexPathsForVisibleRows ?? [];
        let currentAnswer = self.question.answers[indexPath.row];
        if !currentAnswer.isCorrect{
            let index = self.question.answers.index(where: { (answer) -> Bool in
                return answer.isCorrect;
            }) ?? 0;
            
            let cell = tableView.cellForRow(at: IndexPath.init(row: index, section: 0)) as? RNQuestionTableViewCell;
            cell?.markOn();
        }
        
        tableView.allowsSelection = false;
        self.countDownLabel.stop();
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.next();
        }
    }
    
    // MARK: UITableViewDelegate
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
