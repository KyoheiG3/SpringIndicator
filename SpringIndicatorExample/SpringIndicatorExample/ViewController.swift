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
        view.addSubview(defaultIndicator)
        defaultIndicator.startAnimation()
        
        let colors = [UIColor.red(), UIColor.blue(), UIColor.orange(), UIColor.green()]
        var colorsIndex = 0
        
        let colorIndicator = SpringIndicator(frame: CGRect(x: 300, y: 100, width: 20, height: 20))
        colorIndicator.lineColor = colors[colorsIndex]
        colorIndicator.lineWidth = 2
        colorIndicator.rotateDuration = 1
        colorIndicator.strokeDuration = 0.5
        colorIndicator.intervalAnimationsHandler = { indicator in
            if colorsIndex + 1 >= colors.count {
                colorsIndex = 0
            }
            
            indicator.lineColor = colors[colorsIndex]
        }
        view.addSubview(colorIndicator)
        colorIndicator.startAnimation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

