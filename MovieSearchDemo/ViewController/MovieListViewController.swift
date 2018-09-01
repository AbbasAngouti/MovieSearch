//
//  MovieListViewController.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 8/30/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import UIKit

class MovieListViewController: UITableViewController {

    private let cellReuseIdentifier = "Cell"
    
    var movies: [MovieRecord] = []
    let pendingOperations = PendingOperations()
    
    let searchController = UISearchController(searchResultsController: nil)
    var totalResult = 0
    var lastPage = 1
    
    var fetchedMovies = [MovieRecord]()
    var searchKeyword = "e.g. Harry Potter"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchController()
        
        tableView.backgroundColor = UIColor.white
        
        tableView.tableFooterView = UIView()
        
        tableView.estimatedRowHeight = 175
    }
    

    private func customizeNavBar() {
        let titleImageView = UIImageView(image: #imageLiteral(resourceName: "twitterIcon"))
        titleImageView.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        titleImageView.contentMode = .scaleAspectFit
        navigationItem.titleView = titleImageView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        customizeNavBar()
    }
    
    
    private func setupSearchController() {
        searchController.searchBar.placeholder = searchKeyword
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.sizeToFit()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
    }
    
    private func fetchMovies() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        ApiClient.shared.getMovies(for: searchKeyword, page: lastPage) { [unowned self] result in
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
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
        searchController.resignFirstResponder()
        if let searchText = searchController.searchBar.text {
            searchKeyword = searchText
            lastPage = 1
            fetchedMovies.removeAll()
            fetchMovies()
            searchBar.placeholder = searchText
            
        }
        searchController.isActive = false
    }
}


extension MovieListViewController {

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedMovies.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            cell.accessoryView = indicator
        }
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        
        let movieDetails = fetchedMovies[indexPath.row]
        
        cell.textLabel?.text = movieDetails.title
        cell.detailTextLabel?.text = movieDetails.overview
        cell.imageView?.image = movieDetails.poster
        
        switch movieDetails.posterState {
        case .downloaded:
            indicator.stopAnimating()
        case .failed:
            indicator.stopAnimating()
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
        return 175 // subject to A|B testing
    }
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
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // calculates where the user is in the y-axis
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if offsetY > contentHeight - scrollView.frame.size.height {
            fetchMovies()
        }
    }
}
