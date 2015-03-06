//
//  SpringIndicator.swift
//  SpringIndicator
//
//  Created by Kyohei Ito on 2015/03/06.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit

@IBDesignable
public class SpringIndicator: UIView {
    private let LotateAnimationKey = "rotateAnimation"
    private let ExpandAnimationKey = "expandAnimation"
    private let ContractAnimationKey = "contractAnimation"
    
    private let strokeTiming = [0, 0.3, 0.5, 0.7, 1]
    private let strokeValues = [0, 0.1, 0.5, 0.9, 1]
    
    private var rotateThreshold = (M_PI / M_PI_2 * 2) - 1
    private var indicatorView: UIView
    private var animationCount: Double = 0
    private var pathLayer: CAShapeLayer? {
        willSet {
            self.pathLayer?.removeFromSuperlayer()
        }
    }
    
    @IBInspectable public var animating: Bool = false
    @IBInspectable public var lineWidth: CGFloat = 3
    @IBInspectable public var lineColor: UIColor = UIColor.grayColor()
    @IBInspectable public var lotateDuration: Double = 1.5
    @IBInspectable public var strokeDuration: Double = 0.7
    
    public var intervalAnimationsHandler: ((SpringIndicator) -> Void)?
    
    public override init(frame: CGRect) {
        indicatorView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        super.init(frame: frame)
        indicatorView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        addSubview(indicatorView)
        
        backgroundColor = UIColor.clearColor()
    }
    
    public required init(coder aDecoder: NSCoder) {
        indicatorView = UIView()
        super.init(coder: aDecoder)
        indicatorView.frame = bounds
        indicatorView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        addSubview(indicatorView)
    }
    
    private func incrementAnimationCount() -> Double {
        animationCount++
        
        if animationCount > rotateThreshold {
            animationCount = 0
        }
        
        return animationCount
    }
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if animating {
            startAnimation()
        }
    }
    
    private func rotateLayer() -> CAShapeLayer {
        let count = incrementAnimationCount()
        let start = CGFloat(M_PI_2 * (0 - count))
        let end = CGFloat(M_PI_2 * (rotateThreshold - count))
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let radius = max(bounds.width, bounds.height) / 2
        
        var arc = UIBezierPath(arcCenter: center, radius: radius,  startAngle: start, endAngle: end, clockwise: true)
        arc.lineWidth = 0
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = arc.CGPath
        shapeLayer.strokeColor = lineColor.CGColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = kCALineCapRound
        
        return shapeLayer
    }
    
    public func startAnimation() {
        if indicatorView.layer.animationForKey(LotateAnimationKey) != nil {
            return
        }
        
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.duration = lotateDuration
        anim.repeatCount = HUGE
        anim.fromValue = 0
        anim.toValue = M_PI * 2
        indicatorView.layer.addAnimation(anim, forKey: LotateAnimationKey)
        
        nextAnimation()
    }
    
    public func stopAnimation() {
        indicatorView.layer.removeAnimationForKey(LotateAnimationKey)
        pathLayer = nil
    }
    
    private func nextAnimation() {
        intervalAnimationsHandler?(self)
        
        if indicatorView.layer.animationForKey(LotateAnimationKey) == nil {
            return
        }
        
        let shapeLayer = rotateLayer()
        indicatorView.layer.addSublayer(shapeLayer)
        
        pathLayer = shapeLayer
        
        springAnimation()
    }
    
    private func springAnimation() {
        CATransaction.begin()
        CATransaction.setCompletionBlock() {
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(self.nextAnimation)
            
            self.pathLayer?.addAnimation(self.contractAnimation(), forKey: self.ContractAnimationKey)
            CATransaction.commit()
        }
        
        pathLayer?.addAnimation(expandAnimation(), forKey: ExpandAnimationKey)
        CATransaction.commit()
    }
    
    private func contractAnimation() -> CAPropertyAnimation {
        let anim = CAKeyframeAnimation(keyPath: "strokeStart")
        anim.duration = strokeDuration
        anim.keyTimes = strokeTiming
        anim.values = strokeValues
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        
        return anim
    }
    
    private func expandAnimation() -> CAPropertyAnimation {
        let anim = CAKeyframeAnimation(keyPath: "strokeEnd")
        anim.duration = strokeDuration
        anim.keyTimes = strokeTiming
        anim.values = strokeValues
        
        return anim
    }
}
