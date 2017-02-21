//
//  SearchMusicController.swift
//  MusicSearch
//
//  Created by Hafiz Amaduddin Ayub on 2/20/17.
//
//

import UIKit
import Foundation

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}

extension Track {
    init(json: [String: Any]) throws {

        guard let trackName = json["trackName"] as? String else {
            throw SerializationError.missing("trackName")
        }
        
        guard let trackCensoredName = json["trackCensoredName"] as? String else {
            throw SerializationError.missing("trackCensoredName")
        }
        
        guard let artistName = json["artistName"] as? String else {
                throw SerializationError.missing("artistName")
        }
        
        guard let imageURL = json["artworkUrl60"] as? String else {
            throw SerializationError.missing("artworkUrl60")
        }
        
        self.trackName = trackName
        self.trackCensoredName = trackCensoredName
        self.artistName = artistName
        self.imageURL = imageURL
    }
}

struct Track {
    
    var trackName: String
    var trackCensoredName: String
    var artistName: String
    var imageURL: String
}

extension SearchMusicController: UISearchBarDelegate {
    // UISearchBar Delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.global().async {
            searchBar.resignFirstResponder()
            self.searchMusicWithString(searchBar.text!)
        }
    }
}

extension SearchMusicController: UISearchResultsUpdating {
    // UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        DispatchQueue.global().async {
            self.searchMusicWithString(searchBar.text!)
        }
    }
}

extension UIImageView {
    func downloadImageFromLink(_ link:String, contentMode: UIViewContentMode) {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cachesDirectory = paths[0]
        let fileName = cachesDirectory.appendingPathComponent(link) as URL
        if let data = try? Data(contentsOf: fileName) {
            self.image = UIImage(data: data)
            return;
        }
        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: URL(string:link)!, completionHandler: {(data, response, error) -> Void in
                try? data?.write(to: fileName)
                DispatchQueue.main.async {
                    self.contentMode =  contentMode
                    if let data = data { self.image = UIImage(data: data) }
                }
            }).resume()
        }
    }
}

class SearchMusicController: UITableViewController {
  
    // Properties
    let searchController = UISearchController(searchResultsController: nil)
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    var dataTask: URLSessionDataTask?
    var trackList = [Track]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Music Search"
        definesPresentationContext = true
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = true
        
        tableView.tableHeaderView = searchController.searchBar
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // TableViewDataSource/TableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! TrackCell
        
        let track:Track = trackList[indexPath.row]
        cell.artistNameLabel?.text = track.artistName
        cell.trackNameLabel?.text = track.trackName
        cell.trackImage?.downloadImageFromLink(track.imageURL, contentMode: UIViewContentMode.scaleAspectFit)

        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let track: Track = trackList[indexPath.row]
        let lyricsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LyricsViewController") as! LyricsViewController
        lyricsVC.track = track
        navigationController?.pushViewController(lyricsVC, animated: true)
    }
    
    // Request method
    func searchMusicWithString(_ searchString:String) {

        if !searchString.isEmpty {
            if dataTask != nil {
                dataTask?.cancel()
            }
            let searchTerm = searchString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            let urlString  = "https://itunes.apple.com/search?term=" + searchTerm!
            let url = URL(string: urlString)
            dataTask = defaultSession.dataTask(with: url!, completionHandler: {(data, response, error) -> Void in
                if let error = error {
                    print(error.localizedDescription)
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if data != nil {
                            let jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                            let list = jsonData?["results"] as! [Any]
                            var array = [Track]()
                            for case let result in list {
                                let track = try? Track(json: result as! [String : Any])
                                if track != nil {
                                    array.append(track!)
                                }
                            }
                            DispatchQueue.main.async {
                                self.trackList.removeAll()
                                self.trackList += array
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            })
            dataTask?.resume()
        }
    }

}
