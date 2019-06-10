//
//  ViewController.swift
//  MusicPlayer
//
//  Created by Edward on 6/9/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var actionImage: UIImageView!
    @IBOutlet weak var slider: UISlider!
    
    var audioPlayer = AVAudioPlayer()
    var gradientLayer: CAGradientLayer!
    var singleTapGesture = UITapGestureRecognizer()
    var doubleTapGesture = UITapGestureRecognizer()
    var swipeLeftGesture = UISwipeGestureRecognizer()
    var swipeRightGesture = UISwipeGestureRecognizer()
    
    var filemanager = FileManager.default
    var songs = [String]()
    var songIndex = 0
    
    weak var timer: Timer?
    
    let seaGreen = UIColor.init(red: 45.0/255.0, green: 140.0/255.0, blue: 90.0/255.0, alpha: 1)
    let lightGreen = UIColor.init(red: 125.0/255.0, green: 200.0/255.0, blue: 100.0/255.0, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timeFired), userInfo: nil, repeats: true)
        
        let docsPath = Bundle.main.resourcePath!
        do {
            let docsArray = try self.filemanager.contentsOfDirectory(atPath: docsPath)
            for file in docsArray {
                let fileURL = URL(fileURLWithPath: file)
                if fileURL.pathExtension == "mp3" {
                    songs.append(fileURL.deletingPathExtension().lastPathComponent)
                }
            }
        } catch {
            print(error)
        }
        
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
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [seaGreen, lightGreen]
        self.view.layer.insertSublayer(gradientLayer, at: 1)
        
        slider.setThumbImage(UIImage(named:"slider-thumb"), for: .normal)
        slider.setThumbImage(UIImage(named:"slider-thumb"), for: .highlighted)
        
        singleTapGesture = UITapGestureRecognizer()
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.addTarget(self, action: #selector(didSingleTapButton))
        actionImage.addGestureRecognizer(singleTapGesture)
        
        doubleTapGesture = UITapGestureRecognizer()
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.addTarget(self, action: #selector(didDoubleTapScreen))
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
    }
    
    @objc
    func timeFired() {
        if audioPlayer.isPlaying {
            if let image = UIImage(named:"pause-button") {
                actionImage.image = image
            }
            let fraction = audioPlayer.currentTime / audioPlayer.duration
            slider.setValue(Float(fraction), animated: true)
        }
        else {
            if let image = UIImage(named:"play-button") {
                actionImage.image = image
            }
        }
    }
    
    @objc
    func didSingleTapButton(_ sender: UITapGestureRecognizer) {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        }
        else {
            audioPlayer.play()
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timeFired), userInfo: nil, repeats: true)
        }
    }
    
    @objc
    func didDoubleTapScreen(_ sender: UITapGestureRecognizer) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        audioPlayer.play()
    }
    
    @objc
    func didSwipeLeft() {
        do {
            songIndex = abs(songIndex + 1 % songs.count)
            audioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: songs[songIndex], ofType: "mp3")!))
            audioPlayer.prepareToPlay()
        }
        catch {
            print(error)
        }
        audioPlayer.currentTime = 0
        audioPlayer.play()
    }
    
    @objc
    func didSwipeRight() {
        do {
            songIndex = abs(songIndex - 1 % songs.count)
            audioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: songs[songIndex], ofType: "mp3")!))
            audioPlayer.prepareToPlay()
        }
        catch {
            print(error)
        }
        audioPlayer.currentTime = 0
        audioPlayer.play()
    }
    
    @IBAction func sliderDidSlide(_ sender: UISlider) {
        if timer != nil {
            timer?.invalidate()
        }
        
        audioPlayer.stop()
        let sliderVal = Double(sender.value)
        audioPlayer.currentTime = sliderVal * audioPlayer.duration
        audioPlayer.play()
    }
}
