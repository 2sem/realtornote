//
//  RNFavoriteTableViewCell.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 30..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit

class RNFavoriteTableViewCell: UITableViewCell {

    var favor : RNFavoriteInfo!{
        didSet{
            var subject = self.favor.part?.chapter?.subject;
            var chapter = self.favor.part?.chapter;
            var part = self.favor.part;
            
            self.chapterLabel.text = "\(subject?.name ?? "") 〉 \(chapter?.seq.roman ?? ""). \(chapter?.name ?? "")";
            self.partLabel.text = "\(part?.seq ?? 0). \(part?.name ?? "")";
        }
    }
    
    @IBOutlet weak var chapterLabel: UILabel!
    @IBOutlet weak var partLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
