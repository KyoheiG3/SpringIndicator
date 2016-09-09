//
//  WebViewController.swift
//  SpringIndicatorExample
//
//  Created by Kyohei Ito on 2015/04/20.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import SpringIndicator

class WebViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    let refreshControl = SpringIndicator.Refresher()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let url = URL(string: "https://www.apple.com")
        let request = URLRequest(url: url!)
        webView.loadRequest(request)
        
        refreshControl.indicator.lineColor = UIColor.red
        refreshControl.addTarget(self, action: #selector(WebViewController.onRefresh), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onRefresh() {
        webView.reload()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        refreshControl.endRefreshing()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        refreshControl.endRefreshing()
    }
}
