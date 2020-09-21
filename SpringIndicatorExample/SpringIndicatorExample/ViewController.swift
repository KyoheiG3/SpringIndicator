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
        let defaultIndicator = SpringIndicator(frame: CGRect(x: 100, y: 100, width: 60, height: 60))
        defaultIndicator.lineColors = [.red, .blue, .orange, .green]
        defaultIndicator.rotationDuration = 2
        defaultIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(defaultIndicator)

        let topAnchor: NSLayoutYAxisAnchor
        if #available(iOS 11.0, *) {
            topAnchor = view.safeAreaLayoutGuide.topAnchor
        } else {
            topAnchor = topLayoutGuide.topAnchor
        }

        NSLayoutConstraint.activate([
            defaultIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            defaultIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            defaultIndicator.heightAnchor.constraint(equalToConstant: 40),
            defaultIndicator.widthAnchor.constraint(equalToConstant: 40),
        ])
        defaultIndicator.start()

        let colorIndicator = SpringIndicator(frame: CGRect(x: 300, y: 100, width: 20, height: 20))
        colorIndicator.lineColor = UIColor.red
        colorIndicator.lineWidth = 2
        colorIndicator.rotationDuration = 1
        view.addSubview(colorIndicator)
        colorIndicator.start()
    }

}
