//
//  ApiClient.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 8/30/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import Foundation
import UIKit

class ApiClient {
    static let shared = ApiClient()
    
    enum DataFetchError: Error {
        case invalidURL
        case networkError(message: String)
        case invalidResponse
        case serverError
        case nilResult
        case invalidDataFormat
        case jsonError(message: String)
        case invalideDataType(message: String)
        case unknownError
    }
    
    enum ResultType {
        case success(r: APIResult)
        case error(e: DataFetchError)
    }
    
    private init() {}
    
    
    func getMovies(for keyword: String, page: Int, completion: @escaping (_ result: ResultType) -> Void)  {
        let querystringParameters: [String: AnyObject] = ["api_key": Constants.Keys.APIKey as AnyObject,
                                                          "query": keyword as AnyObject,
                                                          "page": page as AnyObject]
        
        guard let url = Helper.makeUrl(baseUrl: Constants.URLs.apiBaseURL, querystringParameters: querystringParameters) else {
            completion(ResultType.error(e: DataFetchError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            /* GUARD: Was there an error? */
            guard error == nil else {
                completion(ResultType.error(e: DataFetchError.networkError(message: error!.localizedDescription)))
                return
            }
            
            /* GUARD: Did we get a successful 2XX or 3xx response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completion(ResultType.error(e: DataFetchError.invalidResponse))
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completion(ResultType.error(e: DataFetchError.nilResult))
                return
            }
            
            do {
                let apiResult = try JSONDecoder().decode(SearchApiResponse.self, from: data) 
                completion(ResultType.success(r: apiResult))
            } catch let parseError {
                completion(ResultType.error(e: DataFetchError.jsonError(message: parseError.localizedDescription)))
            }
        }
        
        task.resume()
    }
    
}


extension UIImage: APIResult {}
