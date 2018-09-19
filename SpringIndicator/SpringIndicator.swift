//
//  SpringIndicator.swift
//  SpringIndicator
//
//  Created by Kyohei Ito on 2015/03/06.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit

@IBDesignable
open class SpringIndicator: UIView {
    deinit {
        stop()
    }

    let indicatorView: UIView
    fileprivate var pathLayer: CAShapeLayer? {
        didSet {
            oldValue?.removeAllAnimations()
            oldValue?.removeFromSuperlayer()

            if let layer = pathLayer {
                indicatorView.layer.addSublayer(layer)
            }
        }
    }

    /// Start the animation automatically in drawRect.
    @IBInspectable open var animating: Bool = false
    /// Line thickness.
    @IBInspectable open var lineWidth: CGFloat = 3
    /// Line Color. Default is gray.
    @IBInspectable open var lineColor: UIColor = UIColor.gray
    /// Line Colors. If set, lineColor is not used.
    open var lineColors: [UIColor] = []
    /// Cap style. Options are `round' and `square'. true is `round`. Default is false
    @IBInspectable open var lineCap: Bool = false
    /// Rotation duration. Default is 1.5
    @IBInspectable open var rotationDuration: Double = 1.5
    private var strokeDuration: Double {
        return rotationDuration / 2
    }

    /// During stroke animation is true.
    open var isSpinning: Bool {
        return pathLayer?.animationExist(for: .spring) == true
    }

    public override init(frame: CGRect) {
        indicatorView = UIView(frame: CGRect(origin: .zero, size: frame.size))
        super.init(frame: frame)
        indicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(indicatorView)
        
        backgroundColor = UIColor.clear
    }
    
    public required init?(coder aDecoder: NSCoder) {
        indicatorView = UIView()
        super.init(coder: aDecoder)
        indicatorView.frame = bounds
        indicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(indicatorView)
        
        backgroundColor = UIColor.clear
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if animating {
            start(for: .begin)
        }
    }

    private func makeRotationPath(for process: AnimationProcess) -> UIBezierPath {
        let start = CGFloat(process.startAngle())
        let end = CGFloat(Double.pi + Double.pi_2) + start
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let radius = max(bounds.width, bounds.height) / 2

        let arc = UIBezierPath(arcCenter: center, radius: radius,  startAngle: start, endAngle: end, clockwise: true)
        arc.lineWidth = 0

        return arc
    }

    private func makeRotationLayer() -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = (lineColors.first ?? lineColor).cgColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = lineCap ? .round : .square

        return shapeLayer
    }

    public func start() {
        start(for: .begin)
    }

    fileprivate func start(for process: AnimationProcess) {
        if isSpinning {
            return
        }

        indicatorView.layer.add(rotationAnimation(for: process), for: .rotation)
        strokeTransaction(process)
    }

    /// If true, waiting for stroke animation.
    public func stop(with waitingForAnimation: Bool = false, completion: ((SpringIndicator) -> Void)? = nil) {
        if waitingForAnimation, let layer = pathLayer?.presentation() {
            let time = Double(2 - layer.strokeStart - layer.strokeEnd)
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                self.stop(completion: completion)
            }
        } else {
            indicatorView.layer.removeAllAnimations()
            pathLayer?.strokeEnd = 0
            pathLayer = nil

            completion?(self)
        }
    }

    private func strokeTransaction(_ process: AnimationProcess) {
        if pathLayer == nil {
            pathLayer = makeRotationLayer()
        }

        pathLayer?.path = makeRotationPath(for: process).cgPath

        CATransaction.begin()
        if process == .during {
            CATransaction.setCompletionBlock() {
                self.pathLayer?.removeAllAnimations()
                self.start(for: .skip)
            }
        } else {
            if lineColors.count > 1 {
                pathLayer?.add(colorAnimation(for: process), for: .color)
            }
        }

        pathLayer?.add(nextAnimation(for: process), for: .spring)
        CATransaction.commit()
    }

    private func nextAnimation(for process: AnimationProcess) -> CAAnimation {
        return process == .during ? strokeAnimation(key: .strokeStart) : springAnimation()
    }

}

// MARK: - Animation
extension SpringIndicator {
    // MARK: for Rotation
    private func rotationAnimation(for process: AnimationProcess) -> CAPropertyAnimation {
        let animation = CABasicAnimation(key: .rotationZ)
        animation.duration = rotationDuration
        animation.repeatCount = HUGE
        animation.fromValue = process.fromAngle()
        animation.toValue = process.toAngle()
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        return animation
    }

    // MARK: for Spring
    private func springAnimation() -> CAAnimationGroup {
        let expand = strokeAnimation(key: .strokeEnd)
        expand.beginTime = 0

        let contract = strokeAnimation(key: .strokeStart)
        contract.beginTime = expand.duration

        let animation = CAAnimationGroup()
        animation.animations = [expand, contract]
        animation.duration = expand.duration + contract.duration
        animation.repeatCount = HUGE
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        return animation
    }

    private func strokeAnimation(key: CAPropertyAnimation.Key) -> CAPropertyAnimation {
        let animation = CAKeyframeAnimation(key: key)
        animation.duration = strokeDuration
        animation.keyTimes = [0, 0.3, 0.5, 0.7, 1]
        animation.values = [0, 0.1, 0.5, 0.9, 1]
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        return animation
    }

    // MARK: for Color
    private func colorAnimation(for process: AnimationProcess) -> CAPropertyAnimation {
        let animation = CAKeyframeAnimation(key: .strokeColor)
        animation.duration = rotationDuration * CFTimeInterval(lineColors.count)
        animation.repeatCount = HUGE
        animation.keyTimes = colorAnimationKeyTimes()
        animation.values = colorAnimationValues(for: process)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }

    private func colorAnimationKeyTimes() -> [NSNumber] {
        let c = Float(lineColors.count)
        return stride(from: 1, through: c, by: 1).reduce([]) { (r: [NSNumber], f: Float) in
            r + [NSNumber(value: f/c-1/c), NSNumber(value: f/c)]
        }
    }

    private func colorAnimationValues(for process: AnimationProcess) -> [CGColor] {
        var colors = ArraySlice(lineColors)
        var first: UIColor?

        if process == .skip {
            first = colors.first
            colors = colors.dropFirst()
        }

        var cgColors = colors.reduce([]) { (r: [CGColor], c: UIColor) in
            r + [c.cgColor, c.cgColor]
        }

        if let first = first {
            cgColors.append(contentsOf: [first.cgColor, first.cgColor])
        }

        return cgColors
    }
}

// MARK: - Stroke
extension SpringIndicator {
    /// between 0.0 and 1.0.
    public func strokeRatio(_ ratio: CGFloat) {
        if ratio <= 0 {
            pathLayer = nil
        } else if ratio >= 1 {
            strokeValue(1)
        } else {
            strokeValue(ratio)
        }
    }

    private func strokeValue(_ value: CGFloat) {
        if pathLayer == nil {
            pathLayer = makeRotationLayer()
            pathLayer?.path = makeRotationPath(for: .begin).cgPath
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pathLayer?.strokeStart = 0
        pathLayer?.strokeEnd = value
        CATransaction.commit()
    }
}

// MARK: - RefreshIndicator extension
extension RefreshIndicator {
    func startIndicatorAnimation() {
        indicator.start(for: .during)
    }

    func stopIndicatorAnimation() {
        indicator.stop() {
            $0.layer.removeAnimation(for: .scale)
        }
    }
}

