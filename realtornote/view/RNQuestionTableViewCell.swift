//
//  RNQuestionTableViewCell.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 8. 14..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit

class RNQuestionTableViewCell: UITableViewCell {
    
    var answer : RNQuestionAnswerInfo?{
        didSet{
            self.titleLagel.text = answer?.title;
        }
    }
    var index = 1{
        didSet{
            self.symbolImage.image = UIImage(named: "icon_\(self.index)_\(self.isSelected ? "on" : "off")");
        }
    }
    
    @IBOutlet weak var symbolImage: UIImageView!
    @IBOutlet weak var markImage: UIImageView!
    @IBOutlet weak var titleLagel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        self.symbolImage.image = UIImage(named: "icon_\(self.index)_\(selected ? "on" : "off")");
        
        if selected{
            self.markOn();
        }else{
            self.markImage.isHidden = true;
        }
    }

    func markOn(){
        self.markImage.isHidden = false;
        self.markImage.image = UIImage(named: "icon_\(self.answer!.isCorrect ? "correct" : "incorrect")");
    }
}
