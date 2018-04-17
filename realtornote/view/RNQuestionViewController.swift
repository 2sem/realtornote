//
//  RNQuestionViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 8. 14..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit

class RNQuestionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var questions : [RNQuestionInfo] = [];
    var question : RNQuestionInfo!;
    var index = 0;
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countDownLabel: LSCountDownLabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.loadQuestion(self.index);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadQuestion(_ index : Int){
        self.question = self.questions[index];
        self.questionLabel.text = self.question.text;
        self.titleLabel.text = self.question.title;

        self.answerTable.reloadData();
        self.answerTable.allowsSelection = true;
        
        self.countDownLabel.start { (remainSeconds) in
            var answer_idx = self.question.answers.enumerated().first(where: { (index, ans) -> Bool in
                return ans.isCorrect;
            });
            
            var cell = self.answerTable.cellForRow(at: IndexPath.init(row: answer_idx!.offset, section: 0)) as? RNQuestionTableViewCell;
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
            return;
        }
        self.loadQuestion(self.index);
    }
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
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
        var cell = tableView.dequeueReusableCell(withIdentifier: "RNQuestionTableViewCell", for: indexPath) as? RNQuestionTableViewCell;
        
        cell!.answer = self.question.answers[indexPath.row];
        cell!.index = indexPath.row + 1;
        
        return cell!;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //var cell = tableView.cellForRow(at: indexPath) as? RNQuestionTableViewCell;
        //cell?.answer?.isCorrect
        
        //var indexes = tableView.indexPathsForVisibleRows ?? [];
        var currentAnswer = self.question.answers[indexPath.row];
        if !currentAnswer.isCorrect{
            var index = self.question.answers.index(where: { (answer) -> Bool in
                return answer.isCorrect;
            }) ?? 0;
            
            var cell = tableView.cellForRow(at: IndexPath.init(row: index, section: 0)) as? RNQuestionTableViewCell;
            cell?.markOn();
        }
        
        tableView.allowsSelection = false;
        self.countDownLabel.stop();
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
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
