//
//  AudioPlayer.swift
//  AudioEnginePlayer
//
//  Created by Edward on 6/13/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class AudioPlayer {
    var engine = AVAudioEngine()
    
    var player = AVAudioPlayerNode()
    
    var audioFile: AVAudioFile!
    var songLengthSamples: AVAudioFramePosition!
    
    var sampleRate: Float = 0
    var lengthSongSeconds: Float = 0
    var startTime: Float = 0
    
    let pitchControl = AVAudioUnitTimePitch()
    let speedControl = AVAudioUnitVarispeed()
    let reverbControl = AVAudioUnitReverb()
    let echoControl = AVAudioUnitDelay()
    let distortionControl = AVAudioUnitDistortion()
    
    private var currentPosition = Float()
    
    init(filename: String) {
        let path = Bundle.main.path(forResource: filename, ofType: "mp3")!
        let url = NSURL.fileURL(withPath: path)
        
        audioFile = try? AVAudioFile(forReading: url)
        songLengthSamples = audioFile.length
        
        let songFormat = audioFile.processingFormat
        sampleRate = Float(songFormat.sampleRate)
        lengthSongSeconds = Float(songLengthSamples) / sampleRate
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile!.processingFormat, frameCapacity: AVAudioFrameCount(audioFile!.length))!
        do {
            try audioFile!.read(into: buffer)
            
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
            }
            catch {
                print(error)
            }
            
        } catch _ {
            
        }
        
        player.volume = 1
        resetDefaultSettings()
        
        engine.attach(player)
        engine.attach(pitchControl)
        engine.attach(speedControl)
        engine.attach(reverbControl)
        engine.attach(echoControl)
        engine.attach(distortionControl)
        
        engine.connect(player, to: pitchControl, format: buffer.format)
        engine.connect(pitchControl, to: speedControl, format: buffer.format)
        engine.connect(speedControl, to: reverbControl, format: buffer.format)
        engine.connect(reverbControl, to: echoControl, format: buffer.format)
        engine.connect(echoControl, to: distortionControl, format: buffer.format)
        engine.connect(distortionControl, to: engine.mainMixerNode, format: buffer.format)
        player.volume = 1
        player.scheduleBuffer(buffer, at:nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
        engine.prepare()
        
        do {
            try engine.start()
        } catch _ {
            
        }
    }
    
    func resetDefaultSettings() {
        pitchControl.pitch = 0
        pitchControl.rate = 1
        pitchControl.overlap = 8
        
        speedControl.rate = 1
        
        reverbControl.loadFactoryPreset(AVAudioUnitReverbPreset.largeHall)
        reverbControl.wetDryMix = 0
        
        echoControl.delayTime = 0
        echoControl.wetDryMix = 0
        echoControl.lowPassCutoff = 15000
        echoControl.feedback = 50
        
        distortionControl.loadFactoryPreset(AVAudioUnitDistortionPreset.drumsLoFi)
        distortionControl.wetDryMix = 0
        distortionControl.preGain = -6
    }
    
    func setVolume(volume: Float) {
        player.volume = volume
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        player.stop()
    }
    
    func replay() {
        player.pause()
        goTo(time: 0)
        player.play()
    }
    
    func getCurrentPosition() -> Float {
        if (player.isPlaying) {
            if let nodeTime = player.lastRenderTime, let playerTime = player.playerTime(forNodeTime: nodeTime) {
                let elapsedSeconds = startTime + (Float(playerTime.sampleTime) / Float(sampleRate))
                currentPosition = elapsedSeconds
            }
        }
        return currentPosition
    }
    
    func goTo(time: Float) {
        player.stop()
        
        let startSample = floor(time * sampleRate)
        let lengthSamples = Float(songLengthSamples) - startSample
        
        player.scheduleSegment(audioFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {self.player.pause()})
        startTime = time
        
        player.play()
    }
}
