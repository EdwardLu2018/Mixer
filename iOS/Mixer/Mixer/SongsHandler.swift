//
//  SongsHandler.swift
//  Mixer
//
//  Created by Edward on 12/16/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import Foundation

final class SongsHandler {
    static var songs: [String] = []
    static var songsExtension: [String] = []
    static var currIndex: Int = 0
    
    static func nextSong() -> String {
        self.currIndex = (self.currIndex + 1) < self.songs.count ? (self.currIndex + 1) : 0
        return self.songsExtension[self.currIndex]
    }
    
    static func prevSong() -> String {
        self.currIndex = (self.currIndex - 1) >= 0 ? (self.currIndex - 1) : (self.songs.count - 1)
        return self.songsExtension[self.currIndex]
    }
}
