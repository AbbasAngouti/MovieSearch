//
//  MovieListViewController.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 8/30/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import UIKit

class MovieListViewController: UITableViewController {

    private let normalCellReuseIdentifier = "NormalCell"
    private let loadCellReuseIdentifier = "LoadMoreCell"
    
    var movies: [MovieRecord] = []
    let pendingOperations = PendingOperations()
    
    let searchController = UISearchController(searchResultsController: nil)
    var totalResult = 0
    var lastPage = 1
    
    var fetchedMovies = [MovieRecord]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchController()
        
//        setupReachability()
        
        tableView.backgroundColor = UIColor.white
        
        // Register cell classes
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: loadCellReuseIdentifier)
        
        tableView.tableFooterView = UIView()
        
        let titleImageView = UIImageView(image: #imageLiteral(resourceName: "twitterIcon"))
        titleImageView.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        titleImageView.contentMode = .scaleAspectFit
        navigationItem.titleView = titleImageView
    }
    

    private func setupSearchController() {
        searchController.searchBar.placeholder = "Harry Potter"
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.sizeToFit()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func fetchMovies(for keyword: String) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        ApiClient.shared.getMovies(for: keyword, page: lastPage) { [unowned self] result in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            self.lastPage += 1
            switch result {
            case .error(let error):
                self.handleError(error: error)
                break
            case .success(let r):
                if let movies = r as? SearchApiResponse {
                    self.handleNewMovies(moviesObject: movies)
                }
                break
            }
        }
    }
    
    
    func handleNewMovies(moviesObject: SearchApiResponse) {
        totalResult = moviesObject.totalResluts
        for movie in moviesObject.movies {
            let m = MovieRecord(movie: movie)
            fetchedMovies.append(m)
        }
        
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
    }
    
    
    func handleError(error: ApiClient.DataFetchError) {
        switch error {
        case .invalidURL:
            print("not a valid URL")
            break
        case .networkError(let message):
            print(message)
            break
        case .invalidResponse:
            print("invalid response from server")
            break
        case .serverError:
            print("unknown error received from server")
            break
        case .nilResult:
            print("unexpected nil in response")
            break
        case .invalidDataFormat:
            break
        case .jsonError(let message):
            print(message)
            break
        case .invalideDataType(let message):
            print(message)
            break
        case .unknownError:
            print("unknown error occured!")
        }
    }
}


extension MovieListViewController: UISearchResultsUpdating, UISearchBarDelegate {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        // TODO
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
        searchController.resignFirstResponder()
        if let searchText = searchController.searchBar.text {
            fetchMovies(for: searchText)
            
        }
        searchController.isActive = false
    }
    
    
}


extension MovieListViewController {
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fetchedMovies.count != totalResult, fetchedMovies.count > 0 { // have not fetched all photos
            return fetchedMovies.count  // one for load more cell
        } else {
            return fetchedMovies.count
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if indexPath.row == fetchedMovies.count { // load-more cell
//            let cell = tableView.dequeueReusableCell(withIdentifier: loadCellReuseIdentifier, for: indexPath)
//            return cell
//        }

        let cell = tableView.dequeueReusableCell(withIdentifier: normalCellReuseIdentifier, for: indexPath)
        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            cell.accessoryView = indicator
        }
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        
        let movieDetails = fetchedMovies[indexPath.row]
        
        cell.textLabel?.text = movieDetails.title
        cell.imageView?.image = movieDetails.poster
        
        switch movieDetails.posterState {
        case .downloaded:
            indicator.stopAnimating()
        case .failed:
            indicator.stopAnimating()
            cell.textLabel?.text = "Failed to load"
        case .new:
            indicator.startAnimating()
            if !tableView.isDragging && !tableView.isDecelerating {
                startOperation(for: movieDetails, at: indexPath)
            }
        }
        
        return cell
    }

    
    func startOperation(for movieRecord: MovieRecord, at indexPath: IndexPath) {
        if movieRecord.posterState == .new {
            startDownload(for: movieRecord, at: indexPath)
        }
    }
    
    
    func startDownload(for movieRecord: MovieRecord, at indexPath: IndexPath) {
        guard pendingOperations.posterDownloadsInProgress[indexPath] == nil else {
            return
        }
        
        let downloader = PosterDownloader(movieRecord)
        
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.pendingOperations.posterDownloadsInProgress.removeValue(forKey: indexPath)
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
        
        pendingOperations.posterDownloadsInProgress[indexPath] = downloader
        
        pendingOperations.posterDownloadQueue.addOperation(downloader)
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MovieListViewController {
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        suspendAllOperations()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadImagesForOnscreenCells()
        resumeAllOperations()
    }
    
    func suspendAllOperations() {
        pendingOperations.posterDownloadQueue.isSuspended = true
    }
    
    func resumeAllOperations() {
        pendingOperations.posterDownloadQueue.isSuspended = false
    }
    
    func loadImagesForOnscreenCells() {
        if let pathsArray = tableView.indexPathsForVisibleRows {
            let allPendingOperations = Set(pendingOperations.posterDownloadsInProgress.keys)
            var toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray)
            toBeCancelled.subtract(visiblePaths)
            
            var toBeStarted = visiblePaths
            toBeStarted.subtract(allPendingOperations)
            
            for indexPath in toBeCancelled {
                if let pendingDownload = pendingOperations.posterDownloadsInProgress[indexPath] {
                    pendingDownload.cancel()
                }
                pendingOperations.posterDownloadsInProgress.removeValue(forKey: indexPath)
            }
            
            for indexPath in toBeStarted {
                let recordToProcess = fetchedMovies[indexPath.row]
                startOperation(for: recordToProcess, at: indexPath)
            }
        }
    }
}




// to monitor internet reachability
extension MovieListViewController {
    
//    func setupReachability() {
//        ReachabilityManager.shared.reachabilityChangeBlock =  reachabilityChanged
//    }
//
//
//    func reachabilityChanged(reachability: Reachability) {
//        switch reachability.currentReachabilityStatus {
//        case .notReachable:
//            if !noConnectionPresented {
//                self.noConnectionPresented = true
//                alert = UIAlertController(title: "No Connection",
//                                          message: "You are not connected to the Internet. Please check you Settings",
//                                          preferredStyle: .alert)
//                present(alert!, animated: true, completion: nil)
//            }
//            break
//        default: // .reachableViaWiFi || .reachableViaWWAN
//            if noConnectionPresented {
//                self.noConnectionPresented = false
//                alert?.dismiss(animated: true, completion: nil)
//            }
//            break
//        }
//    }
}
