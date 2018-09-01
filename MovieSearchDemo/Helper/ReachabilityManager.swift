//
//  ReachabilityManager.swift
//  MovieSearchDemo
//
//  Created by Abbas Angouti on 9/1/18.
//  Copyright © 2018 Abbas Angouti. All rights reserved.
//

import Foundation

import ReachabilitySwift

class ReachabilityManager: NSObject {
    
    static let shared = ReachabilityManager()
    
    var reachabilityChangeBlock: ((Reachability) -> ())? = nil
    
    var isNetworkAvailable : Bool {
        return reachabilityStatus != .notReachable
    }
    
    var reachabilityStatus: Reachability.NetworkStatus = .notReachable
    
    let reachability = Reachability()!
    
    /// Called whenever there is a change in NetworkReachibility Status
    ///
    /// — parameter notification: Notification with the Reachability instance
    @objc func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability
        
        reachabilityChangeBlock?(reachability)
    }
    
    
    /// Starts monitoring the network availability status
    func startMonitoring() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reachabilityChanged),
                                               name: ReachabilityChangedNotification,
                                               object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            debugPrint("Could not initiate reachability notifier")
        }
    }
    
    /// Stops monitoring the network availability status
    func stopMonitoring(){
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: ReachabilityChangedNotification,
                                                  object: reachability)
    }
}
