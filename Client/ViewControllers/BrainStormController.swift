//
//  BrainStormController.swift
//  Client
//
//  Created by Daniel Kharitonov on 6/3/19.
//  Copyright © 2019 Daniel Kharitonov. All rights reserved.
//
//  SIRIKit code attribution: Jeff Rames voice tutorial

import UIKit
import Firebase
import FirebaseDatabase
import Speech
import AVFoundation

class BrainStormController: UIViewController, UITextViewDelegate, SFSpeechRecognizerDelegate {
    
    var sessionID: String = "" {
        didSet {
            Backend.shared.session = sessionID
        }
    }
    
    private var recording: Bool = false
    private var recordingIsEnabled = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))  //1
    private var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask : SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var player: AVAudioPlayer!
    
    // recording image acting as a button
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
            // dead line to update a change in NIB text color
            poster.tintColorDidChange()
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
    
    // this button is disabled when voice recognition runs
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.setTitle("Recording", for: .disabled)
        }
    }
    
    // sending function animates textview if successively posted to Google Firebase
    @IBAction func sendToGoogle(_ sender: UIButton) {
        
        guard let input = poster.text else { return }
        guard poster.text != UIConstants.posterPlaceholder else { return }
        guard poster.text != " " else { return }
        guard poster.text != "" else { return }
        
        let message = [
            "text": input as Any,
            "channel": Backend.shared.channel as Any
            ] as [String : Any]
        
        Backend.shared.updateList(key: "messages", value: message, completionHandler: {
            self.poster.text = ""
            self.curlUp()
        })
    }
    
    private func curlUp() {
        let transitionOptions = UIView.AnimationOptions.transitionCurlUp
        
        UIView.transition(with: self.poster,
                          duration: 1.5,
                          options: [transitionOptions, .showHideTransitionViews],
                          animations: nil,
                          completion: { _ in
                            //can play a sound here but would be too annoying...
        })
        
    }
    
    // MARK: - ViewDidLoad
    // need to listen to changes in channel, session and mode
    // don't care about changes in messagelist here
    override func viewDidLoad() {
        
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(sessionChanged), name: Notification.Name("ChangedSession"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(modeChanged), name: Notification.Name("ChangedMode"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(channelChanged), name: Notification.Name("ChangedChannel"), object: nil)
        
        self.hideKeyboard() 
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        placeholderSet(poster)
        // Do any additional setup after loading the view.
    }
    
    // forces controller to re-read session from AppDelegate if QR was scanned while app running
    @objc func sessionChanged() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let sess = appDelegate.sessionID {
            self.sessionID = sess
        }
    }
    
    // mode change flips client into voting mode
    // note the vote might be in progress when app starts so it will go there immediately
    // also note vote mode is only controlled by the moderator
    @objc func modeChanged() {
        print("new mode: \(Backend.shared.mode)")
        
        if Backend.shared.mode == 1 {
            self.performSegue(withIdentifier: "vote", sender: self)
        }
    }
    
    // channel change switches poster color
    @objc func channelChanged() {
        self.poster.backgroundColor = UIConstants.posterColors[Backend.shared.channel]
    }
    
    @objc func startStop(_ sender: UITapGestureRecognizer) {
        
        var recordingEnabled = false
        
        SFSpeechRecognizer.requestAuthorization{ (authStatus) in
            
            switch authStatus {
                
            case .authorized : recordingEnabled = true
            case .denied : recordingEnabled = false
            print("Speech recognition is denied")
                
            case .restricted : recordingEnabled = false
            print("Speech recognition is restricted")
                
            case .notDetermined : recordingEnabled = false
            
            print("Speech recognition not yet authorized")
            default: recordingEnabled = false
            print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation {
                self.recordingIsEnabled = recordingEnabled
            }
        }
        
        self.speechRecognizer?.delegate = self
        
        if audioEngine.isRunning {
            
            // stopping tasks
            audioEngine.stop()
            recognitionRequest?.endAudio()
            
            self.recordingIsEnabled = false
            self.recording =  false
            self.sendButton.isEnabled = true
            
            
        } else {
            
            // starting tasks
            self.recording =  true
            startRecording()
        }
        
        if self.recording {
            self.sendButton.isEnabled = false
            self.sendButton.alpha = 0.7
            print("started recording")
            
            UIView.animate(
                withDuration: 1.0,
                delay: 0,
                options: [.allowUserInteraction, .repeat, .autoreverse],
                animations: { self.record.alpha = 0.1 },
                completion: nil)
            
        } else {
            
            print("stopped recording")
            self.playTone(action: "off")
            self.sendButton.isEnabled = true
            self.sendButton.alpha = 1.0
            record.layer.removeAllAnimations()
            record.alpha = 1.0
        }
    }
    
    private  func startRecording() {
        
        if  speechRecognitionTask != nil {
            speechRecognitionTask?.cancel()
            speechRecognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
        } catch {
            
            print("audio session was not set")
        }
        
        let inputNode = audioEngine.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard recognitionRequest != nil else {
            fatalError("Audio: no create request instance")
        }
        
        recognitionRequest!.shouldReportPartialResults = true
        
        var savedtext = self.poster.text ?? ""
        
        if savedtext == UIConstants.posterPlaceholder {
            savedtext = ""
        } else {
            savedtext += " "
        }
        
        speechRecognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!, resultHandler: { (result, error) in
            
            var isFinal = false;
            
            if result != nil{
                // save results onscreen
                self.poster.becomeFirstResponder()
                self.poster.text = savedtext + (result?.bestTranscription.formattedString ?? " ")
                self.poster.resignFirstResponder()
                
                isFinal = (result?.isFinal)!
                
                if error != nil || isFinal {
                    
                    self.poster.text += ". "
                    
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.speechRecognitionTask = nil
                    self.recordingIsEnabled = true
                }
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
            
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch{
            print("AudioEngine could not start.")
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        if available {
            self.recordingIsEnabled = true
        } else {
            self.recordingIsEnabled = false
        }
    }
    
    private func playTone(action: String) {
        
        guard let url = Bundle.main.url(forResource: "record_\(action)", withExtension : "mp3") else {return}
        
        do {
            try AVAudioSession.sharedInstance().setCategory((AVAudioSession.Category.playback), mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = player else { return }
            
            player.play()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIConstants.placeholderTextColor {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    fileprivate func placeholderSet(_ textView: UITextView) {
        textView.text = UIConstants.posterPlaceholder
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
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "vote", let _ = segue.destination as? VoteTableViewController {
            //viewController.sessionID = self.session
            print("segueing")
        }
    }
}
