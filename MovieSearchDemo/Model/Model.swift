//
//  Model.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 8/30/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import Foundation
import UIKit

enum PosterState {
    case new, downloaded, failed
}


class MovieRecord {
    let title: String
    let posterUrl: URL?
    var posterState = PosterState.new // state of the poster. new, downloaded, and failed-to-dowload
    var poster = UIImage(named: "Placeholder")
    let overview: String
    
    init(movie: Movie) {
        self.title = movie.title ?? "Title Not Available"
        posterUrl = URL(string: Constants.URLs.imageBaseURL + (movie.posterPath ?? ""))
        overview = movie.overview ?? "Overview Not Available"
    }
}

// we are not using all fields for this particular app
struct Movie: Codable {
    let title: String?
    let posterPath: String?
    let overview: String?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case posterPath = "poster_path"
        case overview
    }
}


struct SearchApiResponse: Codable, APIResult {
    let page: Int
    let totalResluts: Int
    let totalPages: Int
    let movies: [Movie]
    
    private enum CodingKeys: String, CodingKey {
        case page
        case totalResluts = "total_results"
        case totalPages = "total_pages"
        case movies = "results"
    }
}

protocol APIResult {}
