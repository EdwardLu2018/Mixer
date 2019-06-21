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
    
    var audioPlayer = AudioPlayer(filename: "Julien")
    
    @IBOutlet weak var pitchSlider: UISlider!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var reverbSlider: UISlider!
    @IBOutlet weak var echoSlider: UISlider!
    @IBOutlet weak var distortionSlider: UISlider!
    @IBOutlet weak var progressSlider: UISlider!
    
    weak var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
//        audioPlayer.goTo(time: 50)
//        print("init",audioPlayer.getCurrentPosition())
    }
    
    @objc
    func timerFired() {
        progressSlider.setValue(Float(audioPlayer.getCurrentPosition() / audioPlayer.lengthSongSeconds), animated: true)
    }
    
    @IBAction func resetButtonDidPress(_ sender: Any) {
        audioPlayer.replay()
        audioPlayer.resetDefaultSettings()
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
