//
//  Constants.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 8/30/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import Foundation

struct Constants {
    
    struct URLs {
        static let apiBaseURL = "https://api.themoviedb.org/3/search/movie" // to get metadata
        static let imageBaseURL = "https://image.tmdb.org/t/p/w600_and_h900_bestv2" // to download posters
    }
    
    
    struct Keys {
        static let APIKey = "API_KEY" // get your key here: https://www.themoviedb.org/
    }
}

