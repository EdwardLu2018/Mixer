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
    
    var currentPosition = Float()
    
    init(fileurl: URL) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        }
        catch {
            print(error)
        }
        
        let buffer = createBuffer(fileurl: fileurl)
        readBuffer(buffer: buffer)
        resetDefaultNodeSettings()
        attachAndConnectNodes(buffer: buffer)
        scheduleBuffer(buffer: buffer)
    }
    
    private func attachAndConnectNodes(buffer: AVAudioPCMBuffer) {
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
    }
    
    func changeSong(fileurl: URL) {
        let buffer = createBuffer(fileurl: fileurl)
        readBuffer(buffer: buffer)
        resetDefaultNodeSettings()
        scheduleBuffer(buffer: buffer)
    }
    
    private func createBuffer(fileurl: URL) -> AVAudioPCMBuffer {
        audioFile = try? AVAudioFile(forReading: fileurl)
        songLengthSamples = audioFile.length
        
        let songFormat = audioFile.processingFormat
        sampleRate = Float(songFormat.sampleRate)
        lengthSongSeconds = Float(songLengthSamples) / sampleRate
        startTime = 0
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile!.processingFormat, frameCapacity: AVAudioFrameCount(audioFile!.length))!
        return buffer
    }
    
    private func readBuffer(buffer: AVAudioPCMBuffer) {
        do {
            try audioFile!.read(into: buffer)
        } catch {
            print(error)
        }
    }
    
    private func scheduleBuffer(buffer: AVAudioPCMBuffer) {
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: AVAudioPlayerNodeBufferOptions.interrupts, completionHandler: nil)
        startEngine()
    }
    
    func startEngine() {
        engine.prepare()
        
        do {
            try engine.start()
        } catch {
            print(error)
        }
    }
    
    func resetDefaultNodeSettings() {
        player.volume = 1
        
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
    
    func setVolume(_ volume: Float) {
        player.volume = volume
    }
    
    func play() {
        if (!engine.isRunning) {
            startEngine()
        }
        goTo(time: getCurrentPosition())
        player.play()
    }
    
    func pause() {
        if (self.isPlaying()) {
            player.pause()
        }
    }
    
    func stop() {
        if (self.isPlaying()) {
            player.stop()
        }
    }
    
    func replay() {
        if (self.isPlaying()) {
            startEngine()
        }
        player.pause()
        goTo(time: 0)
        player.play()
    }
    
    func isPlaying() -> Bool {
        return player.isPlaying && engine.isRunning
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
        
        player.scheduleSegment(audioFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: nil)
        startTime = time
        
        player.play()
    }
}
