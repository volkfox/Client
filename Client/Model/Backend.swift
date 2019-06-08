//
//  Backend.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/6/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//
//  Model abstraction via Google Firebase
//  Data Schema:
//  root - (sessionID) - messages (list)
//                     - votes (list)
//                     - mode (0/1)          # 0 = submit ideas, 1 = vote on ideas
//                     - channel (integer)   # up to 5 channels can be switched for one sessionID
// example:
// (MPUZKX)---
//            | channel: 0
//            | mode: 0
//            | messages:
//                     | (LZkNeIvUdzUjvWGGVTO)---
//                                               | channel: 2
//                                               | text: "Places to go on CAMPUS!"

import Foundation
import Firebase
import FirebaseDatabase

class Backend {
    
    static let shared = Backend()
    
    var mode = 0
    var channel = 0 {
        didSet {
            self.rebuildMessages()
            // need to display a different set of ideas if voting is going on
            NotificationCenter.default.post(name: Notification.Name("ChangedChannel"), object: nil)
        }
    }
    
    private var messageList : [String: Any] = [:] // all ideas for sessionID in raw Firebase dict format
    private var ideas: [(key: String, text: String, vote: Bool)] = []  // ideas for active channel only
    
    // acessible by vote screen controller to set a number of items to display
    var count: Int {
        get {
            return self.ideas.count
        }
    }
    
    // sessionID
    var session = "" {
        didSet {
            register()
        }
    }
    
    private var modeHandle: DatabaseHandle!
    private var channelHandle: DatabaseHandle!
    private var ideasHandle: DatabaseHandle!
    
    private var ref : DatabaseReference!
    
    private init(){
        ref = Database.database().reference();
    }
    
    private func register() {
        
        guard self.session != "" else { return }
        self.mode = 0
        
        if modeHandle != nil {
            
            ref.removeObserver(withHandle: self.modeHandle)
            ref.removeObserver(withHandle: self.channelHandle)
            ref.removeObserver(withHandle: self.ideasHandle)
        }
        
        modeHandle = ref.child("\(self.session)/mode").observe(.value, with: { (snapshot) in
            
            if let mode = snapshot.value {
                self.mode = mode as? Int ?? 0
                print("new mode: \(self.mode)")
                NotificationCenter.default.post(name: Notification.Name("ChangedMode"), object: nil)
            }
        })
        
        channelHandle = ref.child("\(self.session)/channel").observe(.value, with: { (snapshot) in
            
            if let channel = snapshot.value {
                self.channel = channel as? Int ?? 0
            }
            print("new channel: \(self.channel)")
        })
        
        ideasHandle = ref.child("\(self.session)/messages").observe(.value, with: { (snapshot) in
            
            if let messageList = snapshot.value as? [String: Any] {
                self.messageList = messageList
                self.rebuildMessages()
            }
            //print("messages: \(self.messages)")
            //print("votes: \(self.votes)")
            //print("keys: \(self.keys)")
        })
        
    }
    
    // convert raw Firebase dict into array of active channel ideas
    // updating the list means vote controller must be updated too
    private func rebuildMessages() {
        
        self.ideas = []
        
        for message in self.messageList {
            
            if let m = message.value as? [String: Any], let text = m["text"], let channel = m["channel"] {
                if self.channel == channel as? Int ?? 0, let tx = text as? String {
                    
                    self.ideas.append((message.key, tx, false))
                }
            }
        }
        self.ideas.sort(by: { $0.0 > $1.0 }) // get around firebase returning list entries in random order
        NotificationCenter.default.post(name: Notification.Name("ChangedMessageList"), object: nil)
    }
    
    // Note vote status (true/false) is only valid locally for duration of session
    // restarting the session resets vote status (so you can vote muptiple times if restarting)
    func getVote(row: Int) -> Bool {
        if row < ideas.count {
            return ideas[row].vote
        }
        return false
    }
    
    func toggleVote(row: Int) {
        if row < ideas.count {
            ideas[row].vote = !ideas[row].vote
        }
    }
    
    // we need to store idea's key from Firebase to submit a vote for it
    func getKey(row: Int) -> String {
        if row < ideas.count {
            return ideas[row].key
        }
        return "666"
    }
    
    func getText(row: Int) -> String {
        if row < ideas.count {
            return ideas[row].text
        }
        return "N/A"
    }
    

    
    // add new post to a firebase list rooted at key, run completionHandler closure on success
    func updateList(key: String, value: [String : Any], completionHandler: @escaping () -> Void) {
        
        let listPath = "\(self.session)/\(key)"
        let key = ref.child(listPath).childByAutoId().key ?? "666"
        
        ref.child(listPath).child(key).setValue(value) {
            
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
                completionHandler()
            }
        }
    }
}
