//
//  DYLNetWork.swift
//  DDYAsk
//
//  Created by 季勤强 on 16/4/5.
//  Copyright © 2016年 季勤强. All rights reserved.
//

import Foundation

enum REQUEST_WAY{
    case JSON
    case HTTP
}

struct File {
    let name: String!
    let url: NSURL!
    init(name: String, url: NSURL){
        self.name = name
        self.url = url
    }
}

let SUCCESS_CODE = 0
class NetworkManager {
    
    let method: String!
    let urlString: String!
    let params: Dictionary<String, AnyObject>
    let callback: (data: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void
    let session: NSURLSession = NSURLSession.sharedSession()
    let boundary = "PitayaUGl0YXlh"
    
    var request: NSMutableURLRequest!
    var task: NSURLSessionTask!
    var uploadTask:NSURLSessionUploadTask!
    var requestWay: REQUEST_WAY
    var files: Array<File> = []
    
    init(url: String, method: String, params: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>(), callback: (data: NSDictionary!, response: NSURLResponse!, error: NSError!) -> Void){
        self.urlString = url
        self.method = method
        self.params = params
        self.request = NSMutableURLRequest(URL: NSURL(string: url)!)
        self.callback = callback
        self.requestWay = REQUEST_WAY.JSON
    }
    
    func fire(){
        self.buildRequest()
        if files.count > 0 && method != "GET"{
            uploadFile()
        }else{
            try! self.buildBody()
            self.fireTask()
        }
    }
    
    func buildParams(param: [String: AnyObject]) -> String{
        var components: [(String, String)] = [(String, String)]()
        for key in params.keys.sort(<){
            let value: AnyObject = params[key]!
            components += self.queryComponenrs(key, value)
        }
        let seperator = "&"
        return (components.map{"\($0)=\($1)"} as [String]).joinWithSeparator(seperator)
    }
    
    func queryComponenrs(key: String, _ value: AnyObject) -> [(String, String)]{
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject]{
            for (nestedKey, value) in dictionary{
                components += queryComponenrs("\(key)[\(nestedKey)]", value)
            }
        }else if let array = value as? [AnyObject]{
            for value in array{
                components += queryComponenrs("\(key)", value)
            }
        }else{
            components.appendContentsOf([(escape(key), escape("\(value)"))])
        }
        return components
    }
    
    func escape(string: String) -> String {
        let allowSet: NSCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet()
        return string.stringByAddingPercentEncodingWithAllowedCharacters(allowSet)!
    }
    
    func buildRequest(){
        if self.method == "GET" && self.params.count > 0{
            let url: String = self.urlString + "?" + self.buildParams(self.params)
            print("url: \(url)")
            self.request = NSMutableURLRequest(URL: NSURL(string: url)!)
        }
        request.HTTPMethod = self.method
        request.setValue(cSid, forHTTPHeaderField: "cSid")
        request.setValue("0", forHTTPHeaderField: "cUserId")
        if self.files.count > 0{
            request.addValue("multipart/form-data; boundary=" + self.boundary, forHTTPHeaderField: "Content-Type")
        }else if self.params.count > 0{
            switch self.requestWay{
            case .JSON:
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                break
                
            case .HTTP:
                request.addValue("text/html", forHTTPHeaderField: "Content-Type")
                break;
            }
        }
    }
    
    func buildBody() throws{
        if self.params.count > 0 && self.method != "GET"{
            let data = try NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions.PrettyPrinted)
            request.HTTPBody = data
        }
    }
    
    func fireTask(){
        task = session.dataTaskWithRequest(self.request, completionHandler: { (data, response, error) -> Void in
            print("response: \(response!)")
            let res = response as? NSHTTPURLResponse
            if res == nil || res!.statusCode != 200{
                print("response code: \(res!.statusCode)")
                return ;
            }
            let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            self.callback(data: json, response: response, error: error)
            print("data: \(json),\nerror: \(error)")
        })
        task.resume()
    }
    
    func uploadFile(){
        let data: NSMutableData = NSMutableData()
        if self.files.count > 0 {
            if self.method == "GET" {
                NSLog("\n\n------------------------\nThe remote server may not accept GET method with HTTP body. But Pitaya will send it anyway.\n------------------------\n\n")
            }
            for (key, value) in self.params {
                data.appendData("--\(self.boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData("\(value.description)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            for file in self.files {
                data.appendData("--\(self.boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"\(file.url.lastPathComponent!)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData("Content-Type: image/png\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData(NSData())
                data.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            data.appendData("--\(self.boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        print("data: \(NSString(data: data, encoding: NSUTF8StringEncoding))")
        uploadTask = session.uploadTaskWithRequest(request, fromData: data, completionHandler: {  (data, response, error) -> Void in
            let res = response as? NSHTTPURLResponse
            if res == nil || res!.statusCode != 200{
                print("response code: \(res!.statusCode)")
                return ;
            }
            let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            self.callback(data: json, response: response, error: error)
            print("response:\(response!)\n data: \(json),\nerror: \(error)")
        })
        uploadTask.resume()
    }
    
}