//
//  ViewController.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/3/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Network


class VoiceViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, QRScannerViewDelegate, UITextFieldDelegate {
    
    private var ref : DatabaseReference!
    
    private var imagePicker: UIImagePickerController!
    
    // can be set from App Delegate with URL scheme launcher
    var session : String = "" {
        didSet {
            sessionInput.text = self.session
        }
    }
    
    private var qrData: QRData? = nil {
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
        ref = Database.database().reference();
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        scannerView.frame = CGRect.zero
        
        // avoid delay in displaying the code if launched via IOS camera app
        sessionChanged()
        
        // change session code if app is running and IOS camera scanned another QR
        NotificationCenter.default.addObserver(self, selector: #selector(sessionChanged), name: Notification.Name("ChangedSession"), object: nil)
        
        self.startNetworkMonitor()
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
    
    private func startNetworkMonitor() {
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            
            if path.status == .satisfied {
                print("We're connected!")
                DispatchQueue.main.async {
                    self.navigationController?.navigationBar.barTintColor = nil
                    self.navigationController?.navigationBar.tintColor = UIConstants.themeColor
                }
                
            } else {
                print("No connection.")
                DispatchQueue.main.async {
                    self.navigationController?.navigationBar.barTintColor = .red
                    self.navigationController?.navigationBar.tintColor = .white
                }
            }
            
            print(path.isExpensive)
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
        
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
            sessionInput.text = sess
        }
    }
    
    func transition() {
        
        // some session code error checking needed here
        //if self.session.count == UIConstants.sessionCodeCounter {
        //    self.performSegue(withIdentifier: "brainstorm", sender: self)
        //}
        
        ref.child(session).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            if let _ = snapshot.value as? NSDictionary {
                
                self.performSegue(withIdentifier: "brainstorm", sender: self)
                
            } else {
                
                self.sessionInput.textColor = UIConstants.sessionFieldColorError
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.sessionInput.textColor = UIConstants.sessionFieldColor
                }
                print("wrong session code")
            }
            // ...
        }) { (error) in
            print("firebase err")
            print(error.localizedDescription)
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




