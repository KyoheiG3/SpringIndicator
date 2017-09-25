//
//  CALayer+Animation.swift
//  SpringIndicator
//
//  Created by Kyohei Ito on 2017/09/25.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

extension CALayer {
    enum Animation: String {
        case rotation = "rotationAnimation"
        case expand = "expandAnimation"
        case spring = "springAnimation"
        case color = "colorAnimation"
        case scale = "scaleAnimation"
    }

    func add(_ anim: CAAnimation, for key: Animation) {
        add(anim, forKey: key.rawValue)
    }

    func removeAnimation(for key: Animation) {
        removeAnimation(forKey: key.rawValue)
    }

    func animation(for key: Animation) -> CAAnimation? {
        return animation(forKey: key.rawValue)
    }

    func animationExist(for key: Animation) -> Bool {
        return animation(forKey: key.rawValue) != nil
    }
}
