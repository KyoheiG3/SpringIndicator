//
//  TableViewController.swift
//  SpringIndicatorExample
//
//  Created by Kyohei Ito on 2015/05/18.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import SpringIndicator

class TableViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = SpringIndicator.Refresher()
    
    let dataSourceList: [[String]] = [[Int](0..<20).map({ "section 0, cell \($0)" })]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
    }
    
    func onRefresh() {
        let delay = 2.0 * Double(NSEC_PER_SEC)
        let time  = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.refreshControl.endRefreshing()
        }
    }
}

extension TableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        return view
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceList[section].count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSourceList.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel?.text = "\(indexPath.section) : \(indexPath.row)"
        
        return cell
    }
}