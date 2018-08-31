//
//  AppDelegate.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 8/30/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        configNavigationBar()
        
        return true
    }
}


func configNavigationBar() {
    UINavigationBar.appearance().barTintColor = UIColor(red: 0.114, green: 0.631, blue: 0.949, alpha: 1)
}
