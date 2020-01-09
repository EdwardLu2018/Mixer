//
//  SongViewController.swift
//  Mixer
//
//  Created by Edward on 6/10/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit
import Alamofire

class SongViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var handleArea: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var swipeUpImage: UIImageView!
    
    var delegate: MusicController?
    
    let refreshControl = UIRefreshControl()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        let indexPath = IndexPath(row: SongsHandler.currIndex, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing Songs...")
        refreshControl.addTarget(self, action: #selector(refreshSongs), for: .valueChanged)
    }
    
    @objc func refreshSongs(_ sender: Any) {
        let url = "https://mixerserver.herokuapp.com/dbcontents"
        Alamofire.request(url, method: .get).responseJSON { response in
            if let json = response.result.value {
                SongsHandler.songs = ((json as! NSArray) as! [String]).sorted().map{ $0.components(separatedBy: ".mp3")[0] }
                self.tableView.reloadData()
                let indexPath = IndexPath(row: SongsHandler.currIndex, section: 0)
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SongsHandler.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "songInfo", for: indexPath) as? SongTableViewCell else {
            fatalError("The dequeued cell is not an instance of SongTableViewCell.")
        }
        cell.songTitle.text = SongsHandler.songs[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SongsHandler.currIndex = indexPath.row
        delegate?.getSong(SongsHandler.songsExtension[SongsHandler.currIndex])
    }
}
