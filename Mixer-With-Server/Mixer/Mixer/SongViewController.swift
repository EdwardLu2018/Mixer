//
//  SongViewController.swift
//  Mixer
//
//  Created by Edward on 6/10/19.
//  Copyright © 2019 Edward. All rights reserved.
//

import UIKit
import Alamofire

class SongViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var handleArea: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var swipeUpImage: UIImageView!
    
    let refreshControl = UIRefreshControl()
    @IBOutlet weak var searchBar: UISearchBar!
    
    var isSearching: Bool = false
    
    var currTableIndex = Globals.currIndex
    
    weak var timer: Timer?
    
    var filteredSongs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timeFired), userInfo: nil, repeats: true)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        let indexPath = IndexPath(row: currTableIndex, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing Songs...")
        refreshControl.addTarget(self, action: #selector(refreshSongs), for: .valueChanged)
        
        searchBar.delegate = self
    }
    
    @objc
    func timeFired() {
        if currTableIndex != Globals.currIndex {
            currTableIndex = Globals.currIndex
            let indexPath = IndexPath(row: currTableIndex, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
            tableView.reloadData()
        }
    }
    
    @objc
    func refreshSongs(_ sender: Any) {
        let url = "https://mixerserver.herokuapp.com/dbcontents"
        Alamofire.request(url, method: .get).responseJSON { response in
            if let json = response.result.value {
                Globals.songs = ((json as! NSArray) as! [String]).sorted().map{ $0.components(separatedBy: ".mp3")[0] }
                self.refreshControl.endRefreshing()
                let indexPath = IndexPath(row: self.currTableIndex, section: 0)
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredSongs = Globals.songs.filter({$0.lowercased().prefix(searchText.count) == searchText.lowercased()})
        isSearching = true
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.endEditing(true)
        searchBar.text = ""
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredSongs.count
        }
        return Globals.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "songInfo", for: indexPath) as? SongTableViewCell else {
            fatalError("The dequeued cell is not an instance of SongTableViewCell.")
        }
        if isSearching {
            cell.songTitle.text = filteredSongs[indexPath.row]
        }
        else {
            cell.songTitle.text = Globals.songs[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Globals.currIndex = indexPath.row
    }
}
