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
    
    let refreshControl = RefreshIndicator()
    
    let dataSourceList: [[String]] = [[Int](0..<20).map({ "section 0, cell \($0)" })]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        refreshControl.addTarget(self, action: #selector(TableViewController.onRefresh), for: .valueChanged)

        tableView.addSubview(refreshControl)
    }

    @objc func onRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.refreshControl.endRefreshing()
        }
    }
}

extension TableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        return view
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceList[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSourceList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = "\((indexPath as NSIndexPath).section) : \((indexPath as NSIndexPath).row)"
        
        return cell
    }
}
