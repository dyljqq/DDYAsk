//
//  ViewController.swift
//  DDYAsk
//
//  Created by 季勤强 on 16/4/5.
//  Copyright © 2016年 季勤强. All rights reserved.
//

import UIKit

class AdvisoryViewController: UITableViewController {
    
    let LOGIN = USER_PREFIX + "v1/uapi/user/login"
    let ADVISER_LIST = ADVISER_PREFIX + "adviser/list"
    let ASK = ADVISER_PREFIX + "/advisory/ask"
    let answerNumber = 4
    var dataArray = []
    var sid: String? = ""
    let contents = ["今日行情如何", "推荐个股票", "那支股票比较牛逼？", "老师，今天可以关注哪些板块？？", "老师，601258 可以继续持有嘛！！！", "现在大盘行情如何？",
"请问江南化工还有没有上涨空间，9.92买的...", "老师你好 大盘后续可以怎样操作会相对安全", "老师，600410华胜天成本：20元，请问..."]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let params: Dictionary<String, AnyObject> = ["userName": "18868814424", "password": "dyljqq21"]
        title = "投顾列表"
        createNavigationBar()
        try! Request.post(LOGIN, params: params){
            (data, response, error) -> Void in
            let code: Int = data["errcode"] as! Int
            if code == SUCCESS_CODE{
                self.sid = String(data["sid"]!)
                cSid = self.sid!
                self.adviser()
            }else{
                self.sid = ""
            }
        }
    }
    
    func adviser(){
        let params: Dictionary<String, AnyObject> = ["page": Int(arc4random())%10, "size": 20]
        try! Request.get(ADVISER_LIST, params: params, callback: {
            (data, response, error) -> Void in
            let code: Int = data["errcode"] as! Int
            if code == SUCCESS_CODE{
                self.dataArray = data["datas"] as! NSArray
                self.tableView.reloadData()
            }
        })
    }
    
    func randNumber() -> Int{
        return Int(arc4random()) % 20
    }
    
    func createNavigationBar(){
        let bar = UIBarButtonItem(title: "提问", style: .Plain, target: self, action: "answer")
        self.navigationItem.rightBarButtonItem = bar
        
        let leftBar = UIBarButtonItem(title: "刷新", style: .Plain, target: self, action: "adviser")
        self.navigationItem.leftBarButtonItem = leftBar
    }
    
    func answer(){
        if self.dataArray.count == 0{
            return ;
        }
        for i in 0 ..< answerNumber{
            let adviserId = self.dataArray[i]["adviserId"]!
            let params: Dictionary<String, AnyObject> = ["content": contents[Int(arc4random()) % contents.count], "sid":self.sid!, "adviserId": adviserId!]
            try! Request.uploadFile(ASK + "?sid=" + self.sid!, params: params, callback: {
                (data, response, error) -> Void in
                self.title = data["errmsg"] as? String
            })
        }
    }
    
    //delegate
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("CELL")
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "CELL")
        }
        cell!.textLabel!.text = self.dataArray[indexPath.row]["nickName"] as? String
        return cell!
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

