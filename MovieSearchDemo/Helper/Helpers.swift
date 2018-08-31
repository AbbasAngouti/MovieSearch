//
//  Helpers.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 8/30/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import Foundation

struct Helper {
    static func makeUrl(baseUrl: String, querystringParameters: [String: AnyObject]) -> URL? {
        var urlString = baseUrl
        let escapedParameters = encodeQueryParameters(querystringParameters)
        if !escapedParameters.isEmpty {
            urlString = "\(baseUrl)?\(escapedParameters)"
        }
        
        return URL(string: urlString)
    }
    
    
    static func encodeQueryParameters(_ parameters: [String: AnyObject]) -> String {
        if parameters.isEmpty {
            return ""
        }
        
        var keyValuePairs = Set<String>()
        for (key, value) in parameters {
            // make sure the value is a string
            let stringValue = "\(value)"
            
            // encode it
            let encodedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
            
            // append it
            keyValuePairs.insert(key + "=" + "\(encodedValue!)")
        }
        
        return "\(keyValuePairs.joined(separator: "&"))"
    }
}
