//
//  AnimationProcess.swift
//  SpringIndicator
//
//  Created by Kyohei Ito on 2017/09/25.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

enum AnimationProcess {
    case begin, during, skip

    func startAngle() -> Double {
        switch self {
        case .during:       return Double.pi_4
        case .begin, .skip: return 0
        }
    }

    func fromAngle() -> Double {
        switch self {
        case .during:       return -(Double.pi + Double.pi_2)
        case .begin, .skip: return -(Double.pi * 2 + Double.pi_2)
        }
    }

    func toAngle() -> Double {
        switch self {
        case .during:       return Double.pi
        case .begin, .skip: return 0
        }
    }
}
