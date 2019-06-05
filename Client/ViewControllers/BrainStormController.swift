//
//  BrainStormController.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/3/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class BrainStormController: UIViewController, UITextViewDelegate {
    
    var sessionID: String = ""
    var channel = 0
    var messages: [String] = []
    var mode = 0
    
    var ref : DatabaseReference!
    var recording: Bool = false

    
    
    @IBOutlet weak var record: UIImageView! {
        
        didSet {
            
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.startStop(_:)))
            
            record.isUserInteractionEnabled = true
            record.addGestureRecognizer(gestureRecognizer)
        }
        
    }
    
    @IBOutlet weak var poster: UITextView! {
        didSet {
            poster.delegate = self
            let inset = UIConstants.edgeInset
            poster.textContainerInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: 2*inset)
        }
    }
    @IBAction func clearText(_ sender: UIButton) {
        poster.text = ""
        print("clearing poster")
        clearButton.isEnabled = false
        clearButton.alpha = 0.0
    }
    
    @IBOutlet weak var clearButton: UIButton! {
        didSet {
            clearButton.alpha = 0.0
        }
    }
    
    @IBAction func sendToGoogle(_ sender: UIButton) {
        guard let input = poster.text else {
           return
        }
        //print("sending \(poster.text)")
        let key = ref.child("\(self.sessionID)/messages").childByAutoId().key
        let message = [
            "text": input as Any,
            "channel": self.channel as Any
            ] as [String : Any]
        
        ref.child("\(self.sessionID)/messages").child(key ?? "666").setValue(message)
        poster.text = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard() 
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        placeholderSet(poster)
        self.startFirebase()
        print(sessionID)
        // Do any additional setup after loading the view.
    }
    
    
    @objc func startStop(_ sender: UITapGestureRecognizer) {
        self.recording = !self.recording
        
        if self.recording {
            print("start recording")
        UIView.animate(
            withDuration: 1.0,
            delay: 0,
            options: [.allowUserInteraction, .repeat, .autoreverse],
            animations: { self.record.alpha = 0.1 },
            completion: nil)
        } else {
            print("stop recording")
            record.layer.removeAllAnimations()
            record.alpha = 1.0
        }
    }
    

    
    
    
    func startFirebase() {
        
        ref = Database.database().reference();
        
        ref.child("\(self.sessionID)").observe(.value, with: { (snapshot) in
            let stormDict = snapshot.value as? [String: Any]
            
            if let stormDict = stormDict {
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
            print("mode: \(self.mode)")
            //print("channel: \(self.channel)")
            //print("messages: \(self.messages)")
        })
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIConstants.placeholderTextColor {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    fileprivate func placeholderSet(_ textView: UITextView) {
        textView.text = "type or dictate"
        textView.textColor = UIConstants.placeholderTextColor
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            placeholderSet(textView)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        clearButton.isEnabled = !textView.text.isEmpty
        if clearButton.isEnabled {
            clearButton.alpha = 1.0
        } else {
            clearButton.alpha = 0.0
        }
        //print(poster.text)
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
