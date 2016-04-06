//
//  DYLRequest.swift
//  DDYAsk
//
//  Created by 季勤强 on 16/4/5.
//  Copyright © 2016年 季勤强. All rights reserved.
//

import Foundation

class Request {
    static func post(url: String, params: Dictionary<String, AnyObject>, callback: (data: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void) throws{
        let manager = NetworkManager(url: url, method: "POST", params: params, callback: callback)
        manager.fire()
    }
    
    static func get(url: String, params: Dictionary<String, AnyObject>, callback: (data: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void) throws{
        let manager = NetworkManager(url: url, method: "GET", params: params, callback: callback)
        manager.requestWay = REQUEST_WAY.HTTP
        manager.fire()
    }
    
    static func uploadFile(url: String, params: Dictionary<String, AnyObject>, callback: (data: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void) throws{
        let manager = NetworkManager(url: url, method: "POST", params: params, callback: callback)
        let file = File(name: "file", url: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("wx", ofType: "png")!))
        manager.files = [file]
        manager.requestWay = .HTTP
        manager.fire()
    }
}