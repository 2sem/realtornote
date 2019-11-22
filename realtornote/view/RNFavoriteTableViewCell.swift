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
            let subject = self.favor.part?.chapter?.subject;
            let chapter = self.favor.part?.chapter;
            let part = self.favor.part;
            
            switch self.sortType {
            case .no:
                self.chapterLabel.text = "\(subject?.name ?? "") 〉 \(chapter?.seq.roman ?? ""). \(chapter?.name ?? "")";
                break;
            case .subject:
                self.chapterLabel.text = "\(chapter?.seq.roman ?? ""). \(chapter?.name ?? "")";
                break
            }
            self.partLabel.text = "\(part?.seq ?? 0). \(part?.name ?? "")";
        }
    }
    
    var sortType : RNFavoriteTableViewController.SortType = .no;
    
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
