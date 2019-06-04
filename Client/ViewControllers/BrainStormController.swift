//
//  BrainStormController.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/3/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//

import UIKit

class BrainStormController: UIViewController, UITextViewDelegate {

    var sessionID: String = ""
    
    
    @IBOutlet weak var poster: UITextView! {
        didSet {
            poster.delegate = self
            
        }
    }
    @IBAction func clearText(_ sender: UIButton) {
        poster.text = ""
        print("trying the clear")
        clearButton.isEnabled = false
        clearButton.alpha = 0.0
    }
    
    @IBOutlet weak var clearButton: UIButton! {
        didSet {
          clearButton.alpha = 0.0
        }
    }
    
    @IBAction func sendToGoogle(_ sender: UIButton) {
        print("sending")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard() 
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        poster.text = "type or dictate"
        poster.textColor = UIColor.lightGray
        print(sessionID)
        // Do any additional setup after loading the view.
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "type or dictate"
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        clearButton.isEnabled = !textView.text.isEmpty
        if clearButton.isEnabled {
            clearButton.alpha = 1.0
        } else {
            clearButton.alpha = 0.0
        }
        print(poster.text)
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
