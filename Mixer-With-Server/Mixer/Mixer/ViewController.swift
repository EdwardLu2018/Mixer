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
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var speedSlider: CustomSlider!
    @IBOutlet weak var pitchSlider: CustomSlider!
    @IBOutlet weak var reverbSlider: CustomSlider!
    @IBOutlet weak var echoSlider: CustomSlider!
    @IBOutlet weak var distortionSlider: CustomSlider!
    
    var audioPlayer: AudioPlayer!
    
    var gradientLayer: CAGradientLayer!
    var singleTapGesture = UITapGestureRecognizer()
    var doubleTapGesture = UITapGestureRecognizer()
    var swipeLeftGesture = UISwipeGestureRecognizer()
    var swipeRightGesture = UISwipeGestureRecognizer()
    var panGestureRecognizer = UIPanGestureRecognizer()
    
    var filemanager = FileManager.default
    var songs = [String]()
    var toRemove = String()
    var playedSongs = [URL]()
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
        
        songLabel.center.y -= view.bounds.height
        resetButton.center.y += view.bounds.height
        speedSlider.center.x -= (view.bounds.width + speedSlider.bounds.width/2)
        pitchSlider.center.x += (view.bounds.width + pitchSlider.bounds.width/2)
        reverbSlider.center.x -= (view.bounds.width + reverbSlider.bounds.width/2)
        echoSlider.center.x += (view.bounds.width + echoSlider.bounds.width/2)
        distortionSlider.center.x -= (view.bounds.width + distortionSlider.bounds.width/2)
        
        let group = DispatchGroup()
        group.enter()
        
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
        self.durationLabel.text = ""
        
        let url = "https://mixerserver.herokuapp.com/dbcontents"
        
        Alamofire.request(url, method: .get).responseJSON { response in
            if let json = response.result.value {
//                print("JSON: \(json)") // serialized json response
                self.songs = (json as! NSArray) as! [String]
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            
            self.replayToggleButton.isSelected = false
            self.replayToggleButton.alpha = 0.25
            
            self.setupAudio()
            self.setUpSongViewController()
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
        songs = songs.sorted()
        Globals.songs = songs.map{ $0.components(separatedBy: ".mp3")[0] }
        songLabel.text = songs[songIndex].components(separatedBy: ".mp3")[0]
        Globals.currIndex = songIndex
        getSong(songs.first!)
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
    
    func getSong(_ name: String) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: path)
        let filePath = url.appendingPathComponent(name).path
        
        if !filemanager.fileExists(atPath: filePath) {
            self.songLabel.text = "Loading..."
            let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
            
            let url = "https://mixerserver.herokuapp.com/download"
            
            let parameters = [
                "fileName": name.components(separatedBy: ".mp3")[0]
            ]
            
            Alamofire.download(url, method: .post, parameters: parameters, to: destination).validate(contentType: ["audio/mpeg"]).responseData { response in
                switch response.result {
                case .success:
                    self.playSong(name)
                    break
                case .failure:
                    self.songLabel.text = "Failed to download song.\nPlease try again."
                    break
                }
            }
        }
        else {
            self.playSong(name)
        }
    }
    
    func playSong(_ name: String) {
        let documentsURL = filemanager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try filemanager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            if !fileURLs.isEmpty {
                for fileurl in fileURLs {
//                    print(playedSongs)
                    if fileurl.pathExtension != "mp3" {
                        try filemanager.removeItem(at: fileurl)
                    }
                    else if fileurl.lastPathComponent == name {
                        audioPlayer = AudioPlayer(fileurl: fileurl)
                        audioPlayer.play()
                    }
                    
                    if playedSongs.count > 5 {
                        try filemanager.removeItem(at: playedSongs.removeFirst())
                    }
                    else if !playedSongs.contains(fileurl) {
                        playedSongs.append(fileurl)
                    }
                }
//                print(fileURLs, playedSongs)
//                print()
            }
        }
        catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    @objc
    func timerFired() {
        if audioPlayer != nil {
            durationLabel.text = "\(Int(round(audioPlayer.getCurrentPosition()) / 60)):\(String(format: "%.2d", Int(round(audioPlayer.getCurrentPosition())) % 60)) / \(Int(round(audioPlayer.lengthSongSeconds) / 60)):\(String(format: "%.2d", Int(round(audioPlayer.lengthSongSeconds)) % 60))"
            
            slider.setValue(Float(audioPlayer.getCurrentPosition() / audioPlayer.lengthSongSeconds), animated: true)

            if replayToggleButton.isSelected && audioPlayer.getCurrentPosition() > audioPlayer.lengthSongSeconds {
                replayCurrSong()
            }
            else if songIndex != Globals.currIndex {
                songIndex = Globals.currIndex
                changeSongs()
            }
            else if audioPlayer.getCurrentPosition() > audioPlayer.lengthSongSeconds {
                songIndex = (songIndex + 1) < songs.count ? (songIndex + 1) : 0
                audioPlayer.currentPosition = 0
                changeSongs()
            }
            
            if audioPlayer.isPlaying() {
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
        togglePausePlay()
    }
    
    func togglePausePlay() {
        if audioPlayer != nil {
            if audioPlayer.isPlaying() {
                audioPlayer.pause()
            }
            else {
                audioPlayer.play()
            }
        }
    }
    
    @objc
    func didDoubleTapScreen(_ sender: UITapGestureRecognizer) {
        replayCurrSong()
    }
    
    @objc
    func didSingleTapTableView(_ sender: UITapGestureRecognizer) {
        switch sender.state {
        case .ended:
            animateTransitionIfNeeded(state: nextSongVCState(), duration: 1)
        default:
            break
        }
    }
    
    func replayCurrSong() {
        if audioPlayer != nil {
            audioPlayer.replay()
        }
    }
    
    @objc
    func didSwipeLeft() {
        songIndex = (songIndex + 1) < songs.count ? (songIndex + 1) : 0
        songLabel.center.x += view.frame.width
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseInOut],
            animations: {
                self.songLabel.center.x -= self.view.frame.width
        },
        completion: nil)
        changeSongs()
    }
    
    @objc
    func didSwipeRight() {
        songIndex = (songIndex - 1) >= 0 ? (songIndex - 1) : (songs.count - 1)
        songLabel.center.x -= view.frame.width
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseInOut],
                       animations: {
            self.songLabel.center.x += self.view.frame.width
        },
        completion: nil)
        changeSongs()
    }
    
    func changeSongs() {
        if audioPlayer != nil {
            audioPlayer.stop()
        }
        getSong(songs[songIndex])
        songLabel.text = songs[songIndex].components(separatedBy: ".mp3")[0]
        Globals.currIndex = songIndex
        if let image = UIImage(named: "pause-button") {
            actionImage.image = image
        }
        slider.setValue(0.0, animated: true)
        audioPlayer.resetDefaultNodeSettings()
        resetSliders()
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
        audioPlayer.goTo(time: slider.value * audioPlayer.lengthSongSeconds)
    }
    
    @IBAction func speedSliderDidSlide(_ sender: Any) {
        audioPlayer.speedControl.rate = speedSlider.value
    }
    
    @IBAction func pitchSliderDidSlide(_ sender: Any) {
        audioPlayer.pitchControl.pitch = pitchSlider.value
    }
    
    @IBAction func reverbSliderDidSlide(_ sender: Any) {
        audioPlayer.reverbControl.wetDryMix = reverbSlider.value
    }
    
    @IBAction func echoSliderDidSlide(_ sender: Any) {
        audioPlayer.echoControl.delayTime = TimeInterval(echoSlider.value) * (2.0 / 100)
        audioPlayer.echoControl.wetDryMix = echoSlider.value
    }
    
    @IBAction func distortionSliderDidSlide(_ sender: Any) {
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
        audioPlayer.resetDefaultNodeSettings()
        resetSliders()
    }
    
    func resetSliders() {
        pitchSlider.value = audioPlayer.pitchControl.pitch
        speedSlider.value = audioPlayer.speedControl.rate
        reverbSlider.value = audioPlayer.reverbControl.wetDryMix
        echoSlider.value = Float(audioPlayer.echoControl.delayTime)
        distortionSlider.value = audioPlayer.distortionControl.wetDryMix
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
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                    
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
            
            let rotateAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.songViewController.swipeUpImage.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                case .collapsed:
                    self.songViewController.swipeUpImage.transform = CGAffineTransform(rotationAngle: 0)
                }
            }
            rotateAnimator.startAnimation()
            runningAnimations.append(rotateAnimator)
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
