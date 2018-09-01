//
//  HelpersTest.swift
//  MovieSearchDemoTests
//
//  Created by Abbas Angouti on 9/1/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import XCTest
@testable import MovieSearchDemo

class HelpersTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testEncodeQueryParameters() {
        let keyword = "th!schar*a'g(h)g;n:m@az&g=+$^,a/v b?b%2#[j]"
        let querystringParameters: [String: AnyObject] = ["api_key": Constants.Keys.APIKey as AnyObject,
                                                          "query": keyword as AnyObject,
                                                          /*"page": 1 as AnyObject*/]
        XCTAssertEqual(Helper.encodeQueryParameters(querystringParameters),
                       "api_key=2a61185ef6a27f400fd92820ad9e8537&query=th%21schar%2Aa%27g%28h%29g%3Bn%3Am%40az%26g%3D%2B%24%5E%2Ca%2Fv%20b%3Fb%252%23%5Bj%5D")
    }
    
    
    func testMakeUrl() {
        let querystringParameters: [String: AnyObject] = ["api_key": Constants.Keys.APIKey as AnyObject,
                                                          "query": "nice movie" as AnyObject,
                                                          /*"page": 1 as AnyObject*/]
        XCTAssertEqual(Helper.makeUrl(baseUrl: Constants.URLs.apiBaseURL, querystringParameters: querystringParameters), URL(string: "https://api.themoviedb.org/3/search/movie?api_key=2a61185ef6a27f400fd92820ad9e8537&query=nice%20movie"))
    }
    
}
