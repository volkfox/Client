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
            let prefix = "com.thundr://session?code="
            var code = self.qrData?.codeString ?? prefix + "MPUZKX"
            if  let prefixRange = code.range(of: prefix) {
                code.removeSubrange(prefixRange)
                self.session  =  code
            }
        }
    }
    
    // QR scanner window, starts as empty
    @IBOutlet weak var scannerView: QRScannerView! {
        didSet {
            scannerView.delegate = self
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard()
        scannerView.frame = CGRect.zero
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
    }
    
    
    @objc func launchCamera(_ sender: UITapGestureRecognizer) {
        print("tapped")
        
        scannerView.frame = UIScreen.main.bounds
        if !scannerView.isRunning {
            scannerView.startScanning()
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
        }
        return true
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

