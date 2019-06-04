//
//  ViewController.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/3/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//

import UIKit


class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, QRScannerViewDelegate, UITextFieldDelegate {
    
    var imagePicker: UIImagePickerController!
    
    var session : String = "" {
        didSet {
            sessionInput.text = self.session
        }
    }
    
    var qrData: QRData? = nil {
        didSet {
            print("did set")
            let prefix = "com.thundr://session?code="
            var code = self.qrData?.codeString ?? prefix + "MPPZKX"
            if  let prefixRange = self.qrData?.codeString?.range(of: prefix) {
                code.removeSubrange(prefixRange)
                self.session  =  code
            }
        }
    }
    
    // QR scanner window, starts as empty
    @IBOutlet weak var scannerView: QRScannerView! {
        didSet {
            scannerView.delegate = self
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissQR(_:)))
            scannerView.isUserInteractionEnabled = true
            scannerView.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    
    // code input field
    @IBOutlet weak var sessionInput: UITextField! {
        didSet {
            sessionInput.delegate = self
        }
    }
    
    // QR scanner launcher button
    @IBOutlet weak var QRlauncher: UIImageView! {
        didSet {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.launchCamera(_:)))
            QRlauncher.isUserInteractionEnabled = true
            QRlauncher.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    @IBOutlet weak var brainstorm: UIImageView! {
        didSet {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.launchStorm(_:)))
            brainstorm.isUserInteractionEnabled = true
            brainstorm.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        scannerView.frame = CGRect.zero
        
        sessionChanged()
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionChanged), name: Notification.Name("ChangedSession"), object: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
    }
    
    @objc func launchStorm(_ sender: UITapGestureRecognizer) {
        
        self.transition()
    }
    
    
    @objc func launchCamera(_ sender: UITapGestureRecognizer) {
        print("tapped")
        
        scannerView.frame = UIScreen.main.bounds
        if !scannerView.isRunning {
            scannerView.startScanning()
        }
    }
    
    @objc func dismissQR (_ sender: UITapGestureRecognizer) {

        if scannerView.isRunning {
            scannerView.stopScanning()
        }
        scannerView.frame = CGRect.zero
    }
    
    @objc func sessionChanged() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let sess = appDelegate.sessionID {
            self.session = sess
        }
    }
    
    func transition() {
        
        // some session code error checking needed here
        if self.session.count == UIConstants.sessionCodeCounter {
            self.performSegue(withIdentifier: "brainstorm", sender: self)
        }
    }
    
    func qrScanningDidStop() {
        print("scanning stopped")
    }
    
    func qrScanningDidFail() {
        print("failure")
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        
        if let code = str, code.contains("com.thundr") {
            
            self.qrData = QRData(codeString: str)
            scannerView.frame = CGRect.zero
            
        } else {
            if !scannerView.isRunning {
                scannerView.startScanning()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if let input = sessionInput.text {
            self.session = input
            self.transition()
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "brainstorm", let viewController = segue.destination as? BrainStormController {
            viewController.sessionID = self.session
        }
    }
}

extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}




