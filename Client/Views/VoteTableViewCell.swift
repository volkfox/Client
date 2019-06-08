//
//  VoteTableViewCell.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/7/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//

import UIKit

class VoteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var content: UITextView!
    @IBOutlet weak var likeButton: UIButton!
    
    @IBAction func like(_ sender: UIButton) {
        
        let row = self.buttonAction!(sender)
        let likedBefore = Backend.shared.getVote(row: row)
        
        if !likedBefore {

            let vote = [
                "key": Backend.shared.keys[row] as Any,
                "channel": Backend.shared.channel as Any,
                "vote": 1 as Any
                ] as [String : Any]
            
            Backend.shared.updateList(key: "votes", value: vote, completionHandler: {
                self.likeButton.setImage(UIImage(named: "thumb-black-1"), for: .normal)
                Backend.shared.toggleVote(row: row)
            })
            
        } else {
            
            let vote = [
                "key": Backend.shared.keys[row] as Any,
                "channel": Backend.shared.channel as Any,
                "vote": -1 as Any
                ] as [String : Any]
            
            Backend.shared.updateList(key: "votes", value: vote, completionHandler: {
                self.likeButton.setImage(UIImage(named: "thumb-white-1"), for: .normal)
                Backend.shared.toggleVote(row: row)
            })
        }
    }
    
    var buttonAction: ((Any) -> Int)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
