//
//  ViewController.swift
//  MusicPlayer
//
//  Created by Edward on 6/9/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

struct Globals {
    static var songs = [String]()
    static var currSong = String()
    static var currIndex = Int()
}

class ViewController: UIViewController {

    @IBOutlet weak var actionImage: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var replayToggleButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    
    var audioPlayer = AVAudioPlayer()
    var gradientLayer: CAGradientLayer!
    var singleTapGesture = UITapGestureRecognizer()
    var doubleTapGesture = UITapGestureRecognizer()
    var swipeLeftGesture = UISwipeGestureRecognizer()
    var swipeRightGesture = UISwipeGestureRecognizer()
    var panGestureRecognizer = UIPanGestureRecognizer()
    
    var filemanager = FileManager.default
    var songs = [String]()
    var songIndex = 0
    
    weak var timer: Timer?
    
    enum SongVCState {
        case expanded
        case collapsed
    }
    
    var songViewController: SongViewController!
    var visualEffectView: UIVisualEffectView!
    
    let songVCHeight: CGFloat = 600
    let songVCHandleArea: CGFloat = 50
    
    var songVCVisible = false
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted: CGFloat = 0
    
    let customGreen = UIColor.init(red: 45.0/255.0, green: 140.0/255.0, blue: 50.0/255.0, alpha: 1)
    let lightGreen = UIColor.init(red: 125.0/255.0, green: 200.0/255.0, blue: 100.0/255.0, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            print(error)
        }
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        
        replayToggleButton.isSelected = false
        replayToggleButton.alpha = 0.25
        
        slider.setThumbImage(UIImage(named:"slider-thumb"), for: .normal)
        slider.setThumbImage(UIImage(named:"slider-thumb"), for: .highlighted)

        setupAudio()
        setUpGradient()
        setupGuestures()
        setUpSongViewController()
        
        audioPlayer.play()
    }
    
    // Handles headphone events
    override func remoteControlReceived(with event: UIEvent?) {
        if event!.type == UIEvent.EventType.remoteControl {
            switch event!.subtype {
            case UIEvent.EventSubtype.remoteControlTogglePlayPause:
                togglePausePlay()
                break
            case UIEvent.EventSubtype.remoteControlNextTrack:
                songIndex = (songIndex + 1) < songs.count ? (songIndex + 1) : 0
                changeSongs()
                break
            case UIEvent.EventSubtype.remoteControlPreviousTrack:
                songIndex = (songIndex - 1) > 0 ? (songIndex - 1) : (songs.count - 1)
                changeSongs()
                break
            default:
                break
            }
        }

    }
    
    func setupAudio() {
        let docsPath = Bundle.main.resourcePath!
        do {
            let docsArray = try self.filemanager.contentsOfDirectory(atPath: docsPath)
            for file in docsArray {
                let fileURL = URL(fileURLWithPath: file)
                if fileURL.pathExtension == "mp3" {
                    songs.append(fileURL.deletingPathExtension().lastPathComponent)
                }
            }
        }
        catch {
            print(error)
        }
        
        songs = songs.sorted()
        Globals.songs = songs
        songLabel.text = songs[songIndex]
        Globals.currIndex = songIndex
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: songs[songIndex], ofType: "mp3")!))
            audioPlayer.prepareToPlay()
            
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
            }
            catch {
                print(error)
            }
        }
        catch {
            print(error)
        }
    }
    
    func setUpGradient() {
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
//        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
//        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [lightGreen.cgColor, customGreen.cgColor]
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
        self.view.addGestureRecognizer(doubleTapGesture)
        
        swipeLeftGesture = UISwipeGestureRecognizer()
        swipeLeftGesture.addTarget(self, action: #selector(didSwipeLeft))
        swipeLeftGesture.direction = .left
        self.view.addGestureRecognizer(swipeLeftGesture)
        
        swipeRightGesture = UISwipeGestureRecognizer()
        swipeRightGesture.addTarget(self, action: #selector(didSwipeRight))
        swipeRightGesture.direction = .right
        self.view.addGestureRecognizer(swipeRightGesture)
    }
    
    func setUpSongViewController() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        self.view.sendSubviewToBack(visualEffectView)
        
        if let songViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SongView") as? SongViewController {
            self.songViewController = songViewController
            self.addChild(songViewController)
            self.view.addSubview(songViewController.view)
            
            songViewController.view.frame = CGRect(x: 0.0, y: self.view.frame.height - songVCHandleArea, width: self.view.bounds.width, height: songVCHeight)
            
            songViewController.view.clipsToBounds = true
            
            panGestureRecognizer = UIPanGestureRecognizer()
            panGestureRecognizer.addTarget(self, action: #selector(handleDataPan))
            songViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    @objc
    func timerFired() {
        durationLabel.text = "\(Int(round(audioPlayer.currentTime) / 60)):\(String(format: "%.2d", Int(round(audioPlayer.currentTime)) % 60)) / \(Int(round(audioPlayer.duration) / 60)):\(String(format: "%.2d", Int(round(audioPlayer.duration)) % 60))"
        
        let fraction = audioPlayer.currentTime / audioPlayer.duration
        slider.setValue(Float(fraction), animated: true)

        if replayToggleButton.isSelected && audioPlayer.currentTime > audioPlayer.duration - 0.25 {
            replayCurrSong()
        }
        else if songIndex != Globals.currIndex {
            songIndex = Globals.currIndex
            changeSongs()
        }
        else if audioPlayer.currentTime > audioPlayer.duration - 0.25 {
            songIndex = (songIndex + 1) < songs.count ? (songIndex + 1) : 0
            changeSongs()
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
        togglePausePlay()
    }
    
    func togglePausePlay() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            if let image = UIImage(named: "play-button") {
                actionImage.image = image
            }
        }
        else {
            audioPlayer.play()
            if let image = UIImage(named: "pause-button") {
                actionImage.image = image
            }
        }
    }
    
    @objc
    func didDoubleTapScreen(_ sender: UITapGestureRecognizer) {
        replayCurrSong()
    }
    
    func replayCurrSong() {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        audioPlayer.play()
    }
    
    @objc
    func didSwipeLeft() {
        songIndex = (songIndex + 1) < songs.count ? (songIndex + 1) : 0
        changeSongs()
    }
    
    @objc
    func didSwipeRight() {
        songIndex = (songIndex - 1) >= 0 ? (songIndex - 1) : (songs.count - 1)
        changeSongs()
    }
    
    func changeSongs() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: songs[songIndex], ofType: "mp3")!))
            audioPlayer.prepareToPlay()
        }
        catch {
            print(error)
        }
        songLabel.text = songs[songIndex]
        Globals.currIndex = songIndex
        audioPlayer.currentTime = 0
        audioPlayer.play()
        if let image = UIImage(named: "pause-button") {
            actionImage.image = image
        }
        slider.setValue(0.0, animated: true)
    }
    
    @objc
    func handleDataPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startTransition(state: nextSongVCState(), duration: 1.0)
        case .changed:
            let translation = recognizer.translation(in: self.songViewController.handleArea)
            var fractionComplete = translation.y / songVCHeight
            fractionComplete = songVCVisible ? fractionComplete : -fractionComplete
            updateTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueTransition()
        default:
            break
        }
    }
    
    @IBAction func sliderDidSlide(_ sender: UISlider) {
        audioPlayer.stop()
        audioPlayer.currentTime = Double(sender.value) * audioPlayer.duration
        audioPlayer.play()
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
    
    func nextSongVCState() -> SongVCState {
        return songVCVisible ? .collapsed : .expanded
    }
    
    func animateTransitionIfNeeded(state: SongVCState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.85) {
                switch state {
                case .expanded:
                    self.songViewController.view.frame.origin.y = self.view.frame.height - self.songVCHeight
                case .collapsed:
                    self.songViewController.view.frame.origin.y = self.view.frame.height - self.songVCHandleArea
                }
            }
            frameAnimator.addCompletion { _ in
                self.songVCVisible = !self.songVCVisible
                self.runningAnimations.removeAll()
            }
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.songViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.songViewController.view.layer.cornerRadius = 5
                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.9) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                    
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
        }
    }
    
    func startTransition(state: SongVCState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    
}
