//
//  SongViewController.swift
//  Mixer
//
//  Created by Edward on 6/10/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit

class SongViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var handleArea: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var swipeUpImage: UIImageView!
    
    var currTableIndex = Globals.currIndex
    
    weak var timer: Timer?
    
    var songs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timeFired), userInfo: nil, repeats: true)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        let indexPath = IndexPath(row: currTableIndex, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
    }
    
    @objc
    func timeFired() {
        if currTableIndex != Globals.currIndex {
            currTableIndex = Globals.currIndex
            let indexPath = IndexPath(row: currTableIndex, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Globals.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "songInfo", for: indexPath) as? SongTableViewCell else {
            fatalError("The dequeued cell is not an instance of SongTableViewCell.")
        }
        cell.songTitle.text = Globals.songs[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Globals.currIndex = indexPath.row
    }
}
