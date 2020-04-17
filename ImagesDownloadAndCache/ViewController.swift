//
//  ViewController.swift
//  ImagesDownloadAndCache
//
//  Created by JOEL CRAWFORD on 4/17/20.
//  Copyright © 2020 JOEL CRAWFORD. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    var refreshCtrl: UIRefreshControl!
    var tableData: [AnyObject]!
    
    var task: URLSessionDownloadTask! //for downloading data
    
    var session: URLSession!
    var cache: NSCache<AnyObject,AnyObject>! //for caching images
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        session = URLSession.shared
        
        task = URLSessionDownloadTask() //creating object of task
        
        self.refreshCtrl = UIRefreshControl()
        
        self.refreshCtrl.addTarget(self, action: #selector(ViewController.refreshTableView), for: .valueChanged)
        
        self.refreshControl = refreshCtrl
        
        self.tableData = [] //initialise empty array
        self.cache = NSCache() //initialise cache
        
        
        
        
    }
    
    
    
    @objc func refreshTableView() {
        
        let url:URL! = URL(string: "https://itunes.apple.com/search?term=flappy&entity=software")
        
        task = session.downloadTask(with: url, completionHandler: { (location: URL?, respponse: URLResponse?, error: Error?) -> Void in
            
            if location != nil {
                
                
                let data:Data! = try? Data(contentsOf: location!)
                
                do {
                    
                    let dict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as AnyObject
                    
                    self.tableData = dict.value(forKey: "results") as? [AnyObject]
                    
                    DispatchQueue.main.async {
                        () -> Void in
                        
                        self.tableView.reloadData()
                        self.refreshControl?.endRefreshing()
                    }
                    
                    
                    
                    
                    
                } catch {
                    print("Something went wrong")
                }
            }
            
            
        })
        task.resume()
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath)
        
        let dictionary = self.tableData[indexPath.row]
        
        cell.textLabel!.text = dictionary["trackName"] as? String
        cell.imageView?.image = UIImage(named: "placeholder")
        
        //caching
        
        if (self.cache.object(forKey: (indexPath as NSIndexPath).row as AnyObject) != nil) {
            
            //use cache
            
            print("Cache Image used, no need to download")
            
            cell.imageView?.image = self.cache.object(forKey: (indexPath as NSIndexPath).row as AnyObject) as? UIImage
            
        }  else {
            
            //download if no cached image found
            
            let artWorkURL = dictionary["artworkUrl100"] as! String //get the URL from dictionary
            let url:URL! = URL(string: artWorkURL)
            
            task = session.downloadTask(with: url, completionHandler: { (location, response, error)  in
                
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        
                        //Before we assign the image,  check wether the current cell is visible, to avoid image scrolling on each other
                        
                        if let updateCell = tableView.cellForRow(at: indexPath){
                            
                            let img:UIImage! = UIImage(data: data)
                            
                            updateCell.imageView?.image = img //update the cell with image
                            
                            self.cache.setObject(img, forKey: (indexPath as NSIndexPath).row as AnyObject) //save the image to cache for next time, NB: the key is the row index of that image to keep track of the right image
                        }
                    }
                }
                
            })
            
            task.resume()
            
            
        }
        return cell
        
    }
    
    
}

