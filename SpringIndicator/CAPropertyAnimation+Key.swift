//
//  CAPropertyAnimation+Key.swift
//  SpringIndicator
//
//  Created by Kyohei Ito on 2017/09/25.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

extension CAPropertyAnimation {
    enum Key: String {
        case strokeStart = "strokeStart"
        case strokeEnd = "strokeEnd"
        case strokeColor = "strokeColor"
        case rotationZ = "transform.rotation.z"
        case scale = "transform.scale"
    }

    convenience init(key: Key) {
        self.init(keyPath: key.rawValue)
    }
}
