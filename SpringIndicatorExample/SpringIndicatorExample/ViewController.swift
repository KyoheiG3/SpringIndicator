//
//  ViewController.swift
//  SpringIndicatorExample
//
//  Created by Kyohei Ito on 2015/03/06.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import SpringIndicator

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let defaultIndicator = SpringIndicator(frame: CGRect(x: 100, y: 100, width: 60, height: 60))
        defaultIndicator.lineColors = [.red, .blue, .orange, .green]
        defaultIndicator.rotationDuration = 2
        view.addSubview(defaultIndicator)
        defaultIndicator.start()

        let colorIndicator = SpringIndicator(frame: CGRect(x: 300, y: 100, width: 20, height: 20))
        colorIndicator.lineColor = UIColor.red
        colorIndicator.lineWidth = 2
        colorIndicator.rotationDuration = 1
        view.addSubview(colorIndicator)
        colorIndicator.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

