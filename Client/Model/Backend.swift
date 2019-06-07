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
    
    var channel = 0
    var messages: [String] = []
    var mode = 0
    private var databaseHandle: DatabaseHandle!
    
    var session = "" {
        didSet {
            register()
        }
    }
    
    private var ref : DatabaseReference!
    
    static let shared = Backend()
    
    //Initializer access level change now
    //private init(){}

    private init(){
        
        ref = Database.database().reference();
        //self.session = sessionID
        //register()
        
    }
    
    private func register() {
        
        guard self.session != "" else { return }
        
        if databaseHandle != nil {
            ref.removeObserver(withHandle: self.databaseHandle)
        }
        
        databaseHandle = ref.child("\(self.session)").observe(.value, with: { (snapshot) in
            
            if let stormDict = snapshot.value as? [String: Any] {
                
                self.mode = stormDict["mode"] as? Int ?? 0
                self.channel = stormDict["channel"] as? Int ?? 0
                
                if let messageList = stormDict["messages"]  as? [String: Any] {
                    
                    self.messages = []
                    
                    for message in messageList {
                        if let m = message.value as? [String: Any], let text = m["text"], let channel = m["channel"] {
                            if self.channel == channel as? Int ?? 0, let tx = text as? String {
                                self.messages.append(tx)
                            }
                        }
                    }
                }
            }
            print("brainstorm session mode: \(self.mode)")
            //print("channel: \(self.channel)")
            //print("messages: \(self.messages)")
        })
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
