//
//  ViewController.swift
//  AudioEnginePlayer
//
//  Created by Edward on 6/13/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var audioPlayer: AudioPlayer!
    var songs = [String]()
    var songIndex = Int()
    var filemanager = FileManager.default
    
    var swipeLeftGesture = UISwipeGestureRecognizer()
    var swipeRightGesture = UISwipeGestureRecognizer()
    
    @IBOutlet weak var pitchSlider: UISlider!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var reverbSlider: UISlider!
    @IBOutlet weak var echoSlider: UISlider!
    @IBOutlet weak var distortionSlider: UISlider!
    @IBOutlet weak var progressSlider: UISlider!
    
    weak var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        audioPlayer = AudioPlayer(filename: songs[songIndex])
        // Do any additional setup after loading the view.
        audioPlayer.play()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            print(error)
        }
        
        pitchSlider.value = audioPlayer.pitchControl.pitch
        speedSlider.value = audioPlayer.speedControl.rate
        reverbSlider.value = audioPlayer.reverbControl.wetDryMix
        echoSlider.value = Float(audioPlayer.echoControl.delayTime)
        distortionSlider.value = audioPlayer.distortionControl.wetDryMix
        
        pitchSlider.setThumbImage(UIImage(imageLiteralResourceName: "slider"), for: .normal)
        speedSlider.setThumbImage(UIImage(imageLiteralResourceName: "slider"), for: .normal)
        reverbSlider.setThumbImage(UIImage(imageLiteralResourceName: "slider"), for: .normal)
        echoSlider.setThumbImage(UIImage(imageLiteralResourceName: "slider"), for: .normal)
        distortionSlider.setThumbImage(UIImage(imageLiteralResourceName: "slider"), for: .normal)
        
        swipeLeftGesture = UISwipeGestureRecognizer()
        swipeLeftGesture.addTarget(self, action: #selector(didSwipeLeft))
        swipeLeftGesture.direction = .left
        self.view.addGestureRecognizer(swipeLeftGesture)
        
        swipeRightGesture = UISwipeGestureRecognizer()
        swipeRightGesture.addTarget(self, action: #selector(didSwipeRight))
        swipeRightGesture.direction = .right
        self.view.addGestureRecognizer(swipeRightGesture)
    }
    
    @objc
    func timerFired() {
        progressSlider.setValue(Float(audioPlayer.getCurrentPosition() / audioPlayer.lengthSongSeconds), animated: true)
        print(songIndex)
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
        audioPlayer = AudioPlayer(filename: songs[songIndex])
        resetSliders()
        audioPlayer.play()
    }
    
    @IBAction func resetButtonDidPress(_ sender: Any) {
        audioPlayer.replay()
        resetSliders()
    }
    
    func resetSliders() {
        pitchSlider.value = audioPlayer.pitchControl.pitch
        speedSlider.value = audioPlayer.speedControl.rate
        reverbSlider.value = audioPlayer.reverbControl.wetDryMix
        echoSlider.value = Float(audioPlayer.echoControl.delayTime)
        distortionSlider.value = audioPlayer.distortionControl.wetDryMix
    }
    
    @IBAction func pitchSliderDidSlide(_ sender: Any) {
        audioPlayer.pitchControl.pitch = pitchSlider.value
    }
    
    @IBAction func speedSliderDidSlide(_ sender: Any) {
        audioPlayer.speedControl.rate = speedSlider.value
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
    
    @IBAction func progressSliderDidSlide(_ sender: Any) {
        audioPlayer.goTo(time: progressSlider.value * audioPlayer.lengthSongSeconds)
    }
}
