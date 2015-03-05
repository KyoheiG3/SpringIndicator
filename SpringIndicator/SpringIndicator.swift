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
    
    private var animationCount: CGFloat = 0
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
        super.init(frame: frame)
        
        backgroundColor = UIColor.clearColor()
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func incrementAnimationCount() -> CGFloat {
        animationCount++
        
        if animationCount >= 4 {
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
        let start = CGFloat(M_PI_2) * (0 - count)
        let end = CGFloat(M_PI_2) * (3 - count)
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
        if layer.animationForKey(LotateAnimationKey) != nil {
            return
        }
        
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.duration = lotateDuration
        anim.repeatCount = HUGE
        anim.fromValue = 0
        anim.toValue = M_PI * 2
        layer.addAnimation(anim, forKey: LotateAnimationKey)
        
        nextAnimation()
    }
    
    public func stopAnimation() {
        layer.removeAnimationForKey(LotateAnimationKey)
        pathLayer = nil
    }
    
    private func nextAnimation() {
        intervalAnimationsHandler?(self)
        
        if layer.animationForKey(LotateAnimationKey) == nil {
            return
        }
        
        let shapeLayer = rotateLayer()
        layer.addSublayer(shapeLayer)
        
        pathLayer = shapeLayer
        
        springAnimation()
    }
    
    private func springAnimation() {
        CATransaction.begin()
        CATransaction.setCompletionBlock() {
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(self.nextAnimation)
            
            self.pathLayer?.addAnimation(self.contractSnimation(), forKey: self.ContractAnimationKey)
            CATransaction.commit()
        }
        
        pathLayer?.addAnimation(expandAnimation(), forKey: ExpandAnimationKey)
        CATransaction.commit()
    }
    
    private func contractSnimation() -> CAPropertyAnimation {
        let timing = [0, 0.3, 0.5, 0.7, 1]
        let values = [0, 0.2, 0.5, 0.8, 1]
        let anim = CAKeyframeAnimation(keyPath: "strokeStart")
        anim.duration = strokeDuration
        anim.keyTimes = timing
        anim.values = values
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        
        return anim
    }
    
    private func expandAnimation() -> CAPropertyAnimation {
        let timing = [0, 0.2, 0.5, 0.7, 1]
        let values = [0, 0.1, 0.6, 0.9, 1]
        let anim = CAKeyframeAnimation(keyPath: "strokeEnd")
        anim.duration = strokeDuration
        anim.keyTimes = timing
        anim.values = values
        
        return anim
    }
}
