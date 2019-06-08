//
//  ViewController.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/3/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//
//  Brainstorming App client for IOS

//  Usage: 1. launch web app on https://thundrweb.herokuapp.com to start a new brainstorm (click on cloud)
//         or join existing brainstorm: https://thundrweb.herokuapp.com/session/MPUZKX
//  2. Scan QR code IOS in-app or launch it via IOS camera to join the brainstorm
//  3. Submit new ideas via voice dictation
//  4. Operate web interface to switch channels (tabs) or start voting (click on thumbup button in the upper left corner)
//  5. Note that free hosting tier at heroku can be slow to keep webapp alive. Reload webscreen if vote counts not updating.
//  6. Also note that voting mode is controlled from the web (cannot get out of voting screen on mobile). This per design to force group discussion and focus people on brainstorming tasks.
//
//  Use of APIs in use not covered in class:
//    SIRIKit
//    AVFoundation
//    Google Firebase
//
//    Use of various IOS functions not covered in class:
//        NSNotifications
//        NWPathMonitor
//        URL scheme

//  Build:
//          This project uses cocoa pods for the Firebase support, use 'pod install' to fill dependencies
//          Open .xcworkspace to build the project
//
//  --------------
//  Attribitions:
//        Project uses code snippets from Abhilash KM for QR scanning https://github.com/abhimuralidharan
//        Voice recognition code is modeled largely Jeff Rames voice tutorial, https://www.raywenderlich.com
//        Dismiss keyboard extension uses technique discussed on stackexchange, no author attributed



import UIKit
import Firebase
import FirebaseDatabase
import Network


class VoiceViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, QRScannerViewDelegate, UITextFieldDelegate {
    
    private var ref : DatabaseReference!
    
    private var imagePicker: UIImagePickerController!
    
    // can be set from App Delegate via URL scheme launcher
    var session : String = "" {
        didSet {
            sessionInput.text = self.session
        }
    }
    
    private var qrData: QRData? = nil {
        didSet {
            print("did set")
            let prefix = "com.thundr://session?code="
            var code = self.qrData?.codeString ?? prefix + "UNKNOWN"
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
    
    
    // brainstorm session code input field
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
    
    // Brainstorm image acting as a button for segue to dictation screen
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
        
        // flash red in the titlebar if connection lost
        // not it only shows in screens that have titlebar
        self.startNetworkMonitor()
    }
    
    // don't want barTitle in this screen
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // need to kill scanner if running while segue. Should never happen, just in case.
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
    }
    
    // see Apple docs on definitions of expensive vs cheap path
    private func startNetworkMonitor() {
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            
            if path.status == .satisfied {
                print("We're connected!")
                DispatchQueue.main.async {
                    self.navigationController?.navigationBar.barTintColor = nil
                    self.navigationController?.navigationBar.tintColor = UIConstants.navbarTextColor
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
        
        scannerView.frame = UIScreen.main.bounds
        if !scannerView.isRunning {
            scannerView.startScanning()
        }
    }
    
    // dismiss QR window at any touch
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
        
        // session code validity check: refuse transition if Firebase does not have sessionID node
        
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
        print("QR scan failure")
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






