//
//  VoteTableViewController.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/6/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//
//  List of ideas for voting presented in tableview
//  clicking on "thumbs" button saves vote in backend

import UIKit

class VoteTableViewController: UITableViewController {
    
    @IBOutlet weak var tb: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(modeChanged), name: Notification.Name("ChangedMode"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(channelChanged), name: Notification.Name("ChangedChannel"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(messagesChanged), name: Notification.Name("ChangedMessageList"), object: nil)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @objc func modeChanged() {
        print("goin back: \(Backend.shared.mode)")
        
        if Backend.shared.mode == 0 {
            performSegueToReturnBack()
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    
    @objc func channelChanged() {
        self.tb!.reloadData()
    }
    
    @objc func messagesChanged() {
        let offset = self.tb!.contentOffset
        self.tb!.reloadData()
        self.tb!.contentOffset = offset
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return Backend.shared.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vote", for: indexPath)
        
        // Configure the cell...
        if let tableCell =  cell as? VoteTableViewCell {
            
            let inset = UIConstants.edgeInset
            tableCell.content.textContainerInset = UIEdgeInsets(top: inset*4, left: inset, bottom: inset, right: inset*2)
            
            tableCell.buttonAction = { sender in
                
                var voice = 0
                Backend.shared.toggleVote(row: indexPath.row)
                if Backend.shared.getVote(row: indexPath.row) {
                    voice = 1 } else {
                    voice = -1}
                
                let vote = [
                    "key": Backend.shared.getKey(row: indexPath.row) as Any,
                    "channel": Backend.shared.channel as Any,
                    "vote": voice as Any
                    ] as [String : Any]
                
                print("Sending vote \(vote)")
                Backend.shared.updateList(key: "votes", value: vote, completionHandler: {})
            }
            
            tableCell.content.transform = CGAffineTransform(rotationAngle: CGFloat(Float.random(in: -UIConstants.posterRotationAngle ..< UIConstants.posterRotationAngle)))
            
            tableCell.content.text =
                Backend.shared.getText(row: indexPath.row)
            
            tableCell.liked = Backend.shared.getVote(row: indexPath.row)
            
            tableCell.content.backgroundColor = UIConstants.posterColors[Backend.shared.channel]
            
            tableCell.selectionStyle = .none
        }
        
        return cell
    }
    
}


