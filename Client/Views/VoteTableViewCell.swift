//
//  VoteTableViewCell.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/7/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//
//  View for displaying one idea from a table of brainstorm
//  contains elements: poster (TextView), "like" (UIButton)

import UIKit

class VoteTableViewCell: UITableViewCell {
    
    var liked: Bool = false {
        didSet {
            if liked {
                self.likeButton.setImage(UIImage(named: "thumb-black-1"), for: .normal)
            } else {
                self.likeButton.setImage(UIImage(named: "thumb-white-1"), for: .normal)
            }
        }
    }
    
    // the following outlets initialized from controller
    @IBOutlet weak var content: UITextView!
    @IBAction func like(_ sender: UIButton) {
        
        self.liked = !self.liked
        self.buttonAction?(sender)
    }
    
    @IBOutlet weak var likeButton: UIButton!
    
    // set in closure by controller
    var buttonAction: ((Any) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
