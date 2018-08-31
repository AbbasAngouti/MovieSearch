//
//  MovieOperations.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 8/30/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import Foundation
import UIKit


class PendingOperations {
    lazy var posterDownloadsInProgress: [IndexPath: Operation] = [:]
    lazy var posterDownloadQueue: OperationQueue =  {
        var queue = OperationQueue()
        queue.name = "Poster Download Queue"
        queue.maxConcurrentOperationCount = 1 // subject to an A|B testing to find what number works better
        return queue
    }()
}


class PosterDownloader: Operation {
    let movieRecord: MovieRecord
    
    init(_ movieRecord: MovieRecord) {
        self.movieRecord = movieRecord
    }
    
    private func loadFaild() {
        movieRecord.posterState = .failed
        movieRecord.poster = UIImage(named: "Failed")
    }
    
    private func loadSucceeded(imageData: Data) {
        movieRecord.poster = UIImage(data: imageData)
        movieRecord.posterState = .downloaded
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        guard let posterUrl = movieRecord.posterUrl else {
            loadFaild()
            return
        }
        
        
        guard let imageData = try? Data(contentsOf: posterUrl) else {
            loadFaild()
            return
        }
        
        if isCancelled {
            return
        }
        if !imageData.isEmpty {
            loadSucceeded(imageData: imageData)
        } else {
            loadFaild()
        }
    }
}
