//
//  LyricsViewController.swift
//  MusicSearch
//
//  Created by Hafiz Amaduddin Ayub on 2/20/17.
//
//

import UIKit

class LyricsViewController: UIViewController {

    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var lyricsTV: UITextView!
    @IBOutlet weak var songNameLabel: UILabel!
    
    var track: Track!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
        DispatchQueue.global().async {
            self.getLyrics()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func loadData () {
        title = track.artistName
        songNameLabel.text = track.trackName
        albumImage.downloadImageFromLink(track.imageURL, contentMode: UIViewContentMode.scaleAspectFit)
    }
    
    func getLyrics() {
        
        let urlStr  = "http://lyrics.wikia.com/api.php?func=getSong&fmt=json&artist=" + track.artistName + "&song=" + track.trackCensoredName
        let urlEncodedStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: urlEncodedStr!)
        let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
        let dataTask = defaultSession.dataTask(with: url!, completionHandler: {(data, response, error) -> Void in
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if data != nil {
                        if let jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any] {
                            if let lyricsString = jsonData["lyrics"] as? String {
                                DispatchQueue.main.async {
                                    self.lyricsTV.text = lyricsString
                                }
                            }
                        }
                        else {
                            print("Response is not a valid JSON")
                            if let stringData = String(data: data!, encoding: .utf8) {
                                DispatchQueue.main.async {
                                    self.lyricsTV.text = stringData
                                }
                            } else {
                                print("Response is not a valid String")
                            }
                        }
                    }
                }
            }
        })
        dataTask.resume()
    }

}
