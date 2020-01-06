//
//  ViewController.swift
//  Mixer
//
//  Created by Edward on 6/9/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import Alamofire

protocol MusicController {
    func getSong(_ name: String)
}

class ViewController: UIViewController, MusicController, UIGestureRecognizerDelegate {

    @IBOutlet weak var actionImage: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var replayToggleButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var sliderContainer: UIView!
    @IBOutlet weak var speedSlider: CustomSlider!
    @IBOutlet weak var pitchSlider: CustomSlider!
    @IBOutlet weak var reverbSlider: CustomSlider!
    @IBOutlet weak var echoSlider: CustomSlider!
    @IBOutlet weak var distortionSlider: CustomSlider!
    
    var audioPlayer: AudioPlayer!
    
    var ai = UIActivityIndicatorView()
    
    var gradientLayer: CAGradientLayer!
    var singleTapGesture = UITapGestureRecognizer()
    var doubleTapGesture = UITapGestureRecognizer()
    var swipeLeftGesture = UISwipeGestureRecognizer()
    var swipeRightGesture = UISwipeGestureRecognizer()
    var panGestureRecognizer = UIPanGestureRecognizer()
    
    var filemanager = FileManager.default
    var toRemove: String = ""
    var playedSongs: [URL] = []
    var failedDownload: Bool = false
    var isDownloading: Bool = false
    
    weak var timer: Timer?
    
    var songViewController: SongViewController!
    var visualEffectView: UIVisualEffectView!
    
    let songVCHeight: CGFloat = 610
    let songVCHandleArea: CGFloat = 50
    
    var songVCVisible = false
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted: CGFloat = 0
        
    let darkGreen = UIColor.init(red: 30.0/255.0, green: 210.0/255.0, blue: 95.0/255.0, alpha: 1)
    let darkerGreen = UIColor.init(red: 45.0/255.0, green: 140.0/255.0, blue: 50.0/255.0, alpha: 1)
    let lightGreen = UIColor.init(red: 125.0/255.0, green: 200.0/255.0, blue: 100.0/255.0, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            print(error)
        }
        
        songLabel.center.y -= view.bounds.height
        resetButton.center.y += view.bounds.height
        speedSlider.center.x -= (view.bounds.width + speedSlider.bounds.width/2)
        pitchSlider.center.x += (view.bounds.width + pitchSlider.bounds.width/2)
        reverbSlider.center.x -= (view.bounds.width + reverbSlider.bounds.width/2)
        echoSlider.center.x += (view.bounds.width + echoSlider.bounds.width/2)
        distortionSlider.center.x -= (view.bounds.width + distortionSlider.bounds.width/2)
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseInOut],
                       animations: {
            self.songLabel.center.y += self.view.bounds.height
        },
        completion: nil)
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseInOut],
                       animations: {
            self.resetButton.center.y -= self.view.bounds.height
            self.speedSlider.center.x += (self.view.bounds.width + self.speedSlider.bounds.width/2)
            self.pitchSlider.center.x -= (self.view.bounds.width + self.pitchSlider.bounds.width/2)
            self.reverbSlider.center.x += (self.view.bounds.width + self.reverbSlider.bounds.width/2)
            self.echoSlider.center.x -= (self.view.bounds.width + self.echoSlider.bounds.width/2)
            self.distortionSlider.center.x += (self.view.bounds.width + self.distortionSlider.bounds.width/2)
        },
        completion: nil)
        
        self.setupSliderThumbs()
        self.setUpGradient()
        self.setupGuestures()
        self.songLabel.text = "Loading..."
        self.durationLabel.text = "- - - - -"
        
        let dbURL = "https://mixerserver.herokuapp.com/dbcontents"
        
        Alamofire.request(dbURL, method: .get).responseJSON { response in
            if let json = response.result.value {
                SongsHandler.songsExtension = (json as! NSArray) as! [String]
                SongsHandler.songsExtension = SongsHandler.songsExtension.sorted()
                SongsHandler.songs = SongsHandler.songsExtension.map{ $0.components(separatedBy: ".mp3")[0] }
                
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
                self.replayToggleButton.isSelected = true
                self.setupAudio()
                self.setUpSongViewController()
                
                self.ai = UIActivityIndicatorView(style: .gray)
                self.ai.hidesWhenStopped = true
                self.ai.center = CGPoint(x: self.view.bounds.width/2, y: self.songLabel.center.y/2)
                self.view.insertSubview(self.ai, at: 2)
            }
        }
    }
    
    // Handles headphone events
    override func remoteControlReceived(with event: UIEvent?) {
        if event!.type == UIEvent.EventType.remoteControl {
            switch event!.subtype {
            case UIEvent.EventSubtype.remoteControlTogglePlayPause:
                togglePausePlay()
                break
            case UIEvent.EventSubtype.remoteControlNextTrack:
                changeSong(SongsHandler.nextSong())
                break
            case UIEvent.EventSubtype.remoteControlPreviousTrack:
                changeSong(SongsHandler.prevSong())
                break
            default:
                break
            }
        }
    }
    
    func setupSliderThumbs() {
        slider.setThumbImage(UIImage(named:"slider-thumb"), for: .normal)
        slider.setThumbImage(UIImage(named:"slider-thumb"), for: .highlighted)
        speedSlider.setThumbImage(UIImage(named:"running-rabbit1"), for: .normal)
        speedSlider.setThumbImage(UIImage(named:"running-rabbit1"), for: .highlighted)
        pitchSlider.setThumbImage(UIImage(named:"tuning-fork"), for: .normal)
        pitchSlider.setThumbImage(UIImage(named:"tuning-fork"), for: .highlighted)
        reverbSlider.setThumbImage(UIImage(named:"reverb"), for: .normal)
        reverbSlider.setThumbImage(UIImage(named:"reverb"), for: .highlighted)
        echoSlider.setThumbImage(UIImage(named:"record-filled-echo"), for: .normal)
        echoSlider.setThumbImage(UIImage(named:"record-filled-echo"), for: .highlighted)
        distortionSlider.setThumbImage(UIImage(named:"audio-wave-white"), for: .normal)
        distortionSlider.setThumbImage(UIImage(named:"audio-wave-white"), for: .highlighted)
    }
    
    func setupAudio() {
        songLabel.text = SongsHandler.songs[SongsHandler.currIndex]
        if let firstSong = SongsHandler.songsExtension.randomElement() {
            getSong(firstSong)
        }
    }
    
    func setUpGradient() {
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
//        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
//        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [darkGreen.cgColor, darkerGreen.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setupGuestures() {
        singleTapGesture = UITapGestureRecognizer()
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.addTarget(self, action: #selector(didSingleTapPauseButton))
        singleTapGesture.cancelsTouchesInView = false
        actionImage.addGestureRecognizer(singleTapGesture)
        
        doubleTapGesture = UITapGestureRecognizer()
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.addTarget(self, action: #selector(didDoubleTapScreen))
        doubleTapGesture.cancelsTouchesInView = false
        doubleTapGesture.delegate = self
        self.view.addGestureRecognizer(doubleTapGesture)
        
        swipeLeftGesture = UISwipeGestureRecognizer()
        swipeLeftGesture.addTarget(self, action: #selector(didSwipeLeft))
        swipeLeftGesture.direction = .left
        swipeLeftGesture.delegate = self
        self.view.addGestureRecognizer(swipeLeftGesture)
        
        swipeRightGesture = UISwipeGestureRecognizer()
        swipeRightGesture.addTarget(self, action: #selector(didSwipeRight))
        swipeRightGesture.direction = .right
        swipeRightGesture.delegate = self
        self.view.addGestureRecognizer(swipeRightGesture)
    }
        
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (self.sliderContainer.bounds.contains(touch.location(in: self.sliderContainer))) {
            return false
        }
        else if (self.slider.bounds.contains(touch.location(in: self.slider))) {
            return false
        }
        else if (self.replayToggleButton.bounds.contains(touch.location(in: self.replayToggleButton))) {
            return false
        }
        else if (self.actionImage.bounds.contains(touch.location(in: self.actionImage))) {
            return false
        }
        return true
    }
    
    func playSong(_ name: String) {
        let documentsURL = filemanager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try filemanager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            if !fileURLs.isEmpty {
                for fileurl in fileURLs {
                    if fileurl.pathExtension != "mp3" {
                        try filemanager.removeItem(at: fileurl)
                    }
                    else if fileurl.lastPathComponent == name {
                        audioPlayer = AudioPlayer(fileurl: fileurl)
                        audioPlayer.play()
                        self.songLabel.text = name.components(separatedBy: ".mp3")[0]
                    }
                    
                    if playedSongs.count > 5 {
                        try filemanager.removeItem(at: playedSongs.removeFirst())
                    }
                    else if !playedSongs.contains(fileurl) {
                        playedSongs.append(fileurl)
                    }
                }
            }
        }
        catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    @objc
    func timerFired() {
        if SongsHandler.songs.count != SongsHandler.songs.count {
            SongsHandler.songs = SongsHandler.songs.map{ $0 + ".mp3" }
        }
        
        if let audioPlayer = self.audioPlayer {
            if !self.isDownloading {
                ai.stopAnimating()
                durationLabel.text = "\(Int(round(audioPlayer.getCurrentPosition()) / 60)):\(String(format: "%.2d", Int(round(audioPlayer.getCurrentPosition())) % 60)) / \(Int(round(audioPlayer.lengthSongSeconds) / 60)):\(String(format: "%.2d", Int(round(audioPlayer.lengthSongSeconds)) % 60))"
            }
            else {
                ai.startAnimating()
            }
            
            slider.setValue(Float(audioPlayer.getCurrentPosition() / audioPlayer.lengthSongSeconds), animated: true)

            if replayToggleButton.isSelected && audioPlayer.getCurrentPosition() > audioPlayer.lengthSongSeconds {
                replayCurrSong()
            }
            else if audioPlayer.getCurrentPosition() > audioPlayer.lengthSongSeconds {
                audioPlayer.currentPosition = 0
                changeSong(SongsHandler.nextSong())
            }
            
            if !self.failedDownload {
                if self.audioPlayer.isPlaying() {
                    if let image = UIImage(named: "pause-button") {
                        actionImage.image = image
                    }
                }
                else {
                    if let image = UIImage(named: "play-button") {
                        actionImage.image = image
                    }
                }
            }
            else {
                if let image = UIImage(named: "reset-button") {
                    actionImage.image = image
                }
            }
        }
        else {
            if let image = UIImage(named: "play-button") {
                actionImage.image = image
            }
        }
            
        if songVCVisible {
            singleTapGesture.isEnabled = false
            doubleTapGesture.isEnabled = false
            swipeLeftGesture.isEnabled = false
            swipeRightGesture.isEnabled = false
        }
        else {
            singleTapGesture.isEnabled = true
            doubleTapGesture.isEnabled = true
            swipeLeftGesture.isEnabled = true
            swipeRightGesture.isEnabled = true
        }
    }
    
    @objc
    func didSingleTapPauseButton(_ sender: UITapGestureRecognizer) {
        if !failedDownload {
            togglePausePlay()
        }
        else {
            getSong(SongsHandler.songsExtension[SongsHandler.currIndex])
            failedDownload = false
        }
    }
    
    func togglePausePlay() {
        guard let audioPlayer = audioPlayer else { return }
        if audioPlayer.isPlaying() {
            audioPlayer.pause()
        }
        else {
            audioPlayer.play()
        }
    }
    
    @objc
    func didDoubleTapScreen(_ sender: UITapGestureRecognizer) {
        replayCurrSong()
    }
    
    func replayCurrSong() {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.replay()
    }
    
    @objc
    func didSwipeLeft() {
        songLabel.center.x += view.frame.width
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseInOut],
            animations: {
                self.songLabel.center.x -= self.view.frame.width
        },
        completion: nil)
        changeSong(SongsHandler.nextSong())
    }
    
    @objc
    func didSwipeRight() {
        songLabel.center.x -= view.frame.width
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseInOut],
                       animations: {
            self.songLabel.center.x += self.view.frame.width
        },
        completion: nil)
        changeSong(SongsHandler.prevSong())
    }
    
    func changeSong(_ name: String) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.stop()
        getSong(name)
        songLabel.text = name.components(separatedBy: ".mp3")[0]
        if let image = UIImage(named: "pause-button") {
            actionImage.image = image
        }
        slider.setValue(0.0, animated: true)
        audioPlayer.resetDefaultNodeSettings()
        resetSliders()
        let indexPath = IndexPath(row: SongsHandler.currIndex, section: 0)
        songViewController.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
    }
    
    @IBAction func sliderDidSlide(_ sender: UISlider) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.goTo(time: slider.value * audioPlayer.lengthSongSeconds)
    }
    
    @IBAction func speedSliderDidSlide(_ sender: Any) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.speedControl.rate = speedSlider.value
    }
    
    @IBAction func pitchSliderDidSlide(_ sender: Any) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.pitchControl.pitch = pitchSlider.value
    }
    
    @IBAction func reverbSliderDidSlide(_ sender: Any) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.reverbControl.wetDryMix = reverbSlider.value
    }
    
    @IBAction func echoSliderDidSlide(_ sender: Any) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.echoControl.delayTime = TimeInterval(echoSlider.value) * (2.0 / 100)
        audioPlayer.echoControl.wetDryMix = echoSlider.value
    }
    
    @IBAction func distortionSliderDidSlide(_ sender: Any) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.distortionControl.wetDryMix = distortionSlider.value
    }
    
    @IBAction func didPressReplayButton(_ sender: UIButton) {
        replayToggleButton.isSelected = !replayToggleButton.isSelected

        if replayToggleButton.isSelected {
            replayToggleButton.alpha = 1.0
        }
        else {
            replayToggleButton.alpha = 0.25
        }
    }
    
    @IBAction func didPressResetButton(_ sender: UIButton) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.resetDefaultNodeSettings()
        resetSliders()
    }
    
    func resetSliders() {
        guard let audioPlayer = audioPlayer else { return }
        pitchSlider.value = audioPlayer.pitchControl.pitch
        speedSlider.value = audioPlayer.speedControl.rate
        reverbSlider.value = audioPlayer.reverbControl.wetDryMix
        echoSlider.value = Float(audioPlayer.echoControl.delayTime)
        distortionSlider.value = audioPlayer.distortionControl.wetDryMix
    }
    
}

