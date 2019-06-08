//
//  Backend.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/6/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

class Backend {
    
    static let shared = Backend()
    
    var channel = 0 {
        didSet {
            self.rebuildMessages()
            NotificationCenter.default.post(name: Notification.Name("ChangedChannel"), object: nil)
        }
    }
    
    var messages: [String] = []
    var keys: [String] = []
    var mode = 0
    
    private var votes: [Bool] = []
    private var messageList : [String: Any] = [:]
    
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
                NotificationCenter.default.post(name: Notification.Name("ChangedMode"), object: nil)
            }
            print("new mode: \(self.mode)")
            
        })
        
        channelHandle = ref.child("\(self.session)/channel").observe(.value, with: { (snapshot) in
            
            if let channel = snapshot.value {
                self.channel = channel as? Int ?? 0
            }
            print("new channel: \(self.channel)")
        })
        
        ideasHandle = ref.child("\(self.session)/messages").observe(.value, with: { (snapshot) in
            
            //print("mess \(snapshot.value)")
            
            if let messageList = snapshot.value as? [String: Any] {
                self.messageList = messageList
                self.rebuildMessages()
            }
            print("messages: \(self.messages)")
            print("votes: \(self.votes)")
            print("keys: \(self.keys)")
        })
        
        /*
        databaseHandle = ref.child("\(self.session)").observe(.value, with: { (snapshot) in
            
            if let stormDict = snapshot.value as? [String: Any] {
                
                let newmode = stormDict["mode"] as? Int ?? 0
                
                if self.mode != newmode {
                    self.mode = newmode
                    NotificationCenter.default.post(name: Notification.Name("ChangedMode"), object: nil)
                } else {
                    self.mode = newmode
                }
                
                self.channel = stormDict["channel"] as? Int ?? 0
                
                if let messageList = stormDict["messages"]  as? [String: Any] {

                    self.messageList = messageList
                    self.rebuildMessages()
                }
            }
            print("brainstorm session mode: \(self.mode)")
            //print("channel: \(self.channel)")
            print("messages: \(self.messages)")
            print("votes: \(self.votes)")
            print("keys: \(self.keys)")
        }) */
    }
    
    private func rebuildMessages() {
        
        self.messages = []
        self.keys = []
        self.votes = []
        
        for message in self.messageList {
            
            if let m = message.value as? [String: Any], let text = m["text"], let channel = m["channel"] {
                if self.channel == channel as? Int ?? 0, let tx = text as? String {

                    self.messages.append(tx)
                    self.keys.append(message.key)
                    self.votes.append(false)
                }
            }
        }
    }
    
    func getVote(row: Int) -> Bool {
        if row < votes.count {
            return votes[row]
        }
        return false
    }
    
    func toggleVote(row: Int) {
        if row < votes.count {
            votes[row] = !votes[row]
        }
    }
    
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
