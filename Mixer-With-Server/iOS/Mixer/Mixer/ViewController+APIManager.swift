//
//  ViewController+APIManager.swift
//  Mixer
//
//  Created by Edward on 12/16/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import Alamofire

extension ViewController {
    
    func getSong(_ name: String) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: path)
        let filePath = url.appendingPathComponent(name).path
        
        if !filemanager.fileExists(atPath: filePath) {
            self.songLabel.text = "Loading..."
            let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
            
            let downloadURL = "https://mixerserver.herokuapp.com/download"
            
            let parameters = [
                "fileName": name.components(separatedBy: ".mp3")[0]
            ]
            
            Alamofire.download(downloadURL, method: .post, parameters: parameters, to: destination).validate(contentType: ["audio/mpeg"]).downloadProgress { (progress) in
                self.isDownloading = true
                    self.durationLabel.text = "Percentage Downloaded: \(Int(round(progress.fractionCompleted*100)))"
                }
                .responseData { response in
                switch response.result {
                case .success:
                    self.isDownloading = false
                    self.playSong(name)
                    break
                case .failure:
                    if let audioPlayer = self.audioPlayer {
                        audioPlayer.stop()
                    }
                    self.songLabel.text = "Failed to download song.\nPlease try again."
                    self.failedDownload = true
                    self.isDownloading = false
                    break
                }
            }
        }
        else {
            self.playSong(name)
        }
    }
}
