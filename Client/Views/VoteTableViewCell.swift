//
//  VoteTableViewCell.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/7/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//

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
    
    @IBOutlet weak var content: UITextView!
    @IBOutlet weak var likeButton: UIButton!
    
    @IBAction func like(_ sender: UIButton) {

        self.liked = !self.liked
        self.buttonAction?(sender)
    }
    
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
