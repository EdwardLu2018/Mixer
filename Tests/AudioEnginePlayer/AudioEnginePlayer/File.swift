//
//  File.swift
//  AudioEnginePlayer
//
//  Created by Edward on 6/13/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import Foundation

class EasyPlayer {
    var engine: AVAudioEngine!
    var player: AVAudioPlayerNode!
    var audioFile : AVAudioFile!
    var songLengthSamples: AVAudioFramePosition!
    
    var sampleRateSong: Float = 0
    var lengthSongSeconds: Float = 0
    var startInSongSeconds: Float = 0
    
    let pitch : AVAudioUnitTimePitch
    
    init() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        player.volume = 1.0
        
        let path = Bundle.main.path(forResource: "filename", ofType: "mp3")!
        let url = NSURL.fileURL(withPath: path)
        
        audioFile = try? AVAudioFile(forReading: url)
        songLengthSamples = audioFile.length
        
        let songFormat = audioFile.processingFormat
        sampleRateSong = Float(songFormat.sampleRate)
        lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile!.processingFormat, frameCapacity: AVAudioFrameCount(audioFile!.length))
        do {
            try audioFile!.read(into: buffer)
        } catch _ {
        }
        
        pitch = AVAudioUnitTimePitch()
        pitch.pitch = 1
        pitch.rate = 1
        
        engine.attach(player)
        engine.attach(pitch)
        engine.connect(player, to: pitch, format: buffer.format)
        engine.connect(pitch, to: engine.mainMixerNode, format: buffer.format)
        player.scheduleBuffer(buffer, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
        engine.prepare()
        
        do {
            try engine.start()
        } catch _ {
        }
    }
    
    func setPitch(_ pitch: Float) {
        self.pitch.pitch = pitch
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func getCurrentPosition() -> Float {
        if(self.player.isPlaying){
            if let nodeTime = self.player.lastRenderTime, let playerTime = player.playerTime(forNodeTime: nodeTime) {
                let elapsedSeconds = startInSongSeconds + (Float(playerTime.sampleTime) / Float(sampleRateSong))
                print("Elapsed seconds: \(elapsedSeconds)")
                return elapsedSeconds
            }
        }
        return 0
    }
    
    func seekTo(time: Float) {
        player.stop()
        
        let startSample = floor(time * sampleRateSong)
        let lengthSamples = Float(songLengthSamples) - startSample
        
        player.scheduleSegment(audioFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {self.player.pause()})
        player.play()
    }
}
