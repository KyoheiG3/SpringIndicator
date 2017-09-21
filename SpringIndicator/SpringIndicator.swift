//
//  SpringIndicator.swift
//  SpringIndicator
//
//  Created by Kyohei Ito on 2015/03/06.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit

extension Double {
    fileprivate static let pi_2 = pi / 2
    fileprivate static let pi_4 = pi / 4
}

@IBDesignable
open class SpringIndicator: UIView {
    deinit {
        stopAnimation(false)
    }
    
    fileprivate typealias Me = SpringIndicator
    
    fileprivate static let RotateAnimationKey = "rotateAnimation"
    fileprivate static let ExpandAnimationKey = "expandAnimation"
    fileprivate static let ContractAnimationKey = "contractAnimation"
    fileprivate static let GroupAnimationKey = "groupAnimation"
    
    fileprivate static let StrokeTiming: [NSNumber] = [0, 0.3, 0.5, 0.7, 1]
    fileprivate static let StrokeValues: [NSNumber] = [0, 0.1, 0.5, 0.9, 1]
    
    fileprivate let indicatorView: UIView
    fileprivate var pathLayer: CAShapeLayer? {
        didSet {
            oldValue?.removeAllAnimations()
            oldValue?.removeFromSuperlayer()
        }
    }
    
    /// Start the animation automatically in drawRect.
    @IBInspectable open var animating: Bool = false
    /// Line thickness.
    @IBInspectable open var lineWidth: CGFloat = 3
    /// Line Color. Default is gray.
    @IBInspectable open var lineColor: UIColor = UIColor.gray
    /// Cap style. Options are `round' and `square'. true is `round`. Default is false
    @IBInspectable open var lineCap: Bool = false
    /// Rotation duration. Default is 1.5
    @IBInspectable open var rotateDuration: Double = 1.5
    fileprivate var strokeDuration: Double {
        return rotateDuration / 2
    }
    
    fileprivate var stopAnimationsHandler: ((SpringIndicator) -> Void)?
    
    public override init(frame: CGRect) {
        indicatorView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
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
            startAnimation()
        }
    }
    
    /// During stroke animation is true.
    open func isSpinning() -> Bool {
        return pathLayer?.animation(forKey: Me.ContractAnimationKey) != nil || pathLayer?.animation(forKey: Me.GroupAnimationKey) != nil
    }
    
    open class Refresher: UIControl {
        fileprivate typealias Me = Refresher
        
        fileprivate static let ObserverOffsetKeyPath = "contentOffset"
        fileprivate static let ScaleAnimationKey = "scaleAnimation"
        fileprivate static let DefaultContentHeight: CGFloat = 60
        
        fileprivate var RefresherContext = UInt8()
        fileprivate var initialInsetTop: CGFloat = 0
        open let indicator = SpringIndicator(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        open fileprivate(set) var refreshing: Bool = false
        open var targetView: UIScrollView? {
            willSet {
                removeObserver()
            }
            didSet {
                addObserver()
            }
        }
        
        deinit {
            indicator.stopAnimation(false)
        }
        
        public convenience init() {
            self.init(frame: CGRect.zero)
        }
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            setupIndicator()
        }
        
        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            setupIndicator()
        }
        
        open override func layoutSubviews() {
            super.layoutSubviews()
            
            backgroundColor = UIColor.clear
            isUserInteractionEnabled = false
            
            if let scrollView = superview as? UIScrollView {
                autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
                frame.size.height = Me.DefaultContentHeight
                frame.size.width = scrollView.bounds.width
                center.x = scrollView.center.x
            }
            
            if let scrollView = targetView {
                initialInsetTop = scrollView.contentInset.top
            }
        }
        
        open override func willMove(toSuperview newSuperview: UIView!) {
            super.willMove(toSuperview: newSuperview)
            
            targetView = newSuperview as? UIScrollView
        }
        
        open override func didMoveToSuperview() {
            super.didMoveToSuperview()
            
            layoutIfNeeded()
        }
        
        open override func removeFromSuperview() {
            if targetView == superview {
                targetView = nil
            }
            super.removeFromSuperview()
        }
        
        weak var target: AnyObject?
        open override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControlEvents) {
            super.addTarget(target, action: action, for: controlEvents)
            
            self.target = target as AnyObject?
        }
        
        open override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControlEvents) {
            super.removeTarget(target, action: action, for: controlEvents)
            
            self.target = nil
        }
        
        open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if context == &RefresherContext {
                if let scrollView = object as? UIScrollView {
                    if target == nil {
                        targetView = nil
                        return
                    }
                    
                    if bounds.height <= 0 {
                        return
                    }
                    
                    if superview == scrollView {
                        frame.origin.y = scrollOffset(scrollView)
                    }
                    
                    if indicator.isSpinning() {
                        return
                    }
                    
                    if refreshing && scrollView.isDragging == false {
                        refreshStart(scrollView)
                        return
                    }
                    
                    let ratio = scrollRatio(scrollView)
                    refreshing = ratio >= 1
                    
                    indicator.strokeRatio(ratio)
                    rotateRatio(ratio)
                }
            } else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            }
        }
    }

    fileprivate func nextRotatePath(_ expand: Bool) -> UIBezierPath {
        let pi = CGFloat(expand ? Double.pi_4 : 0)
        let start = pi
        let end = CGFloat(Double.pi + Double.pi_2) + pi
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let radius = max(bounds.width, bounds.height) / 2
        
        let arc = UIBezierPath(arcCenter: center, radius: radius,  startAngle: start, endAngle: end, clockwise: true)
        arc.lineWidth = 0
        
        return arc
    }
    
    fileprivate func rotateLayer() -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = lineColor.cgColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = lineCap ? kCALineCapRound : kCALineCapSquare
        
        return shapeLayer
    }
}

// MARK: - Animation
public extension SpringIndicator {
    /// If start from a state in spread is True.
    public func startAnimation(_ expand: Bool = false) {
        stopAnimationsHandler = nil
        
        if isSpinning() {
            return
        }
        
        let animation = rotateAnimation(rotateDuration, expand: expand)
        indicatorView.layer.add(animation, forKey: Me.RotateAnimationKey)
        
        strokeTransaction(expand)
    }
    
    /// true is wait for stroke animation.
    public func stopAnimation(_ waitAnimation: Bool, completion: ((SpringIndicator) -> Void)? = nil) {
        if waitAnimation {
            stopAnimationsHandler = { indicator in
                indicator.stopAnimation(false, completion: completion)
            }
        } else {
            stopAnimationsHandler = nil
            indicatorView.layer.removeAllAnimations()
            pathLayer?.strokeEnd = 0
            pathLayer = nil
            
            if Thread.current.isMainThread {
                completion?(self)
            } else {
                DispatchQueue.main.async {
                    completion?(self)
                }
            }
        }
    }
    
    fileprivate func strokeTransaction(_ expand: Bool) {
        if pathLayer == nil {
            let layer = rotateLayer()
            pathLayer = layer
            indicatorView.layer.addSublayer(layer)
        }

        pathLayer?.path = nextRotatePath(expand).cgPath

        if expand {
            CATransaction.setCompletionBlock() {
                self.pathLayer?.removeAllAnimations()
                self.startAnimation()
            }
        }

        let animation = nextStrokeAnimation(expand)
        let animationKey = nextAnimationKey(expand)
        pathLayer?.add(animation, forKey: animationKey)
    }

    fileprivate func nextAnimationKey(_ expand: Bool) -> String {
        return expand ? Me.ContractAnimationKey : Me.GroupAnimationKey
    }
    
    fileprivate func nextStrokeAnimation(_ expand: Bool) -> CAAnimation {
        return expand ? contractAnimation(strokeDuration) : groupAnimation(strokeDuration)
    }
    
    // MARK: animations
    fileprivate func rotateAnimation(_ duration: CFTimeInterval, expand: Bool) -> CAPropertyAnimation {
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.duration = duration
        anim.repeatCount = HUGE
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        if expand {
            anim.fromValue = -(Double.pi + Double.pi_2)
            anim.toValue = Double.pi
        } else {
            anim.fromValue = -(Double.pi * 2 + Double.pi_2)
            anim.toValue = 0
        }

        return anim
    }
    
    fileprivate func groupAnimation(_ duration: CFTimeInterval) -> CAAnimationGroup {
        let expand = expandAnimation(duration)
        expand.beginTime = 0
        
        let contract = contractAnimation(duration)
        contract.beginTime = duration
        
        let anim = CAAnimationGroup()
        anim.animations = [expand, contract]
        anim.duration = duration * 2
        anim.repeatCount = HUGE
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        
        return anim
    }
    
    fileprivate func contractAnimation(_ duration: CFTimeInterval) -> CAPropertyAnimation {
        let anim = CAKeyframeAnimation(keyPath: "strokeStart")
        anim.duration = duration
        anim.keyTimes = Me.StrokeTiming
        anim.values = Me.StrokeValues
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        
        return anim
    }
    
    fileprivate func expandAnimation(_ duration: CFTimeInterval) -> CAPropertyAnimation {
        let anim = CAKeyframeAnimation(keyPath: "strokeEnd")
        anim.duration = duration
        anim.keyTimes = Me.StrokeTiming
        anim.values = Me.StrokeValues
        
        return anim
    }
}

// MARK: - Stroke
public extension SpringIndicator {
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
            let shapeLayer = rotateLayer()
            shapeLayer.path = nextRotatePath(false).cgPath
            pathLayer = shapeLayer
            indicatorView.layer.addSublayer(shapeLayer)
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pathLayer?.strokeStart = 0
        pathLayer?.strokeEnd = value
        CATransaction.commit()
    }
}

// MARK: - Refresher
extension SpringIndicator.Refresher {
    fileprivate func setupIndicator() {
        indicator.lineWidth = 2
        indicator.rotateDuration = 1
        indicator.center = center
        indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        addSubview(indicator)
    }
    
    fileprivate func addObserver() {
        targetView?.addObserver(self, forKeyPath: Me.ObserverOffsetKeyPath, options: .new, context: &RefresherContext)
    }
    
    fileprivate func removeObserver() {
        targetView?.removeObserver(self, forKeyPath: Me.ObserverOffsetKeyPath, context: &RefresherContext)
    }
    
    fileprivate func notObserveBlock(_ block: (() -> Void)) {
        removeObserver()
        block()
        addObserver()
    }
    
    fileprivate func scrollOffset(_ scrollView: UIScrollView) -> CGFloat {
        var offsetY = scrollView.contentOffset.y
        offsetY += initialInsetTop
        
        return offsetY
    }
    
    fileprivate func scrollRatio(_ scrollView: UIScrollView) -> CGFloat {
        var offsetY = scrollOffset(scrollView)
        
        offsetY += frame.size.height - indicator.frame.size.height
        if offsetY > 0 {
            offsetY = 0
        }
        
        return abs(offsetY / bounds.height)
    }
    
    fileprivate func rotateRatio(_ ratio: CGFloat) {
        let value = max(min(ratio, 1), 0)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        indicator.indicatorView.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi - Double.pi_4) * value, 0, 0, 1)
        CATransaction.commit()
    }
}

// MARK: - Refresher start
private extension SpringIndicator.Refresher {
    func refreshStart(_ scrollView: UIScrollView) {
        sendActions(for: .valueChanged)
        indicator.layer.add(refreshStartAnimation(), forKey: Me.ScaleAnimationKey)
        indicator.startAnimation(true)
        
        let insetTop = initialInsetTop + bounds.height
        
        notObserveBlock {
            scrollView.contentInset.top = insetTop
        }
        
        scrollView.contentOffset.y -= insetTop - initialInsetTop
    }
    
    func refreshStartAnimation() -> CAPropertyAnimation {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.duration = 0.1
        anim.repeatCount = 1
        anim.autoreverses = true
        anim.fromValue = 1
        anim.toValue = 1.3
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        return anim
    }
}

// MARK: - Refresher end
public extension SpringIndicator.Refresher {
    /// Must be explicitly called when the refreshing has completed
    public func endRefreshing() {
        refreshing = false
        
        if let scrollView = targetView {
            let insetTop: CGFloat
            
            if scrollView.superview?.superview == nil {
                insetTop = 0
            } else {
                insetTop = initialInsetTop
            }
            
            if scrollView.contentInset.top > insetTop {
                let completionBlock: (() -> Void) = {
                    self.indicator.stopAnimation(false) { indicator in
                        indicator.layer.removeAnimation(forKey: Me.ScaleAnimationKey)
                    }
                }
                
                let beforeOffsetY = scrollView.contentOffset.y
                scrollView.contentInset.top = insetTop
                
                if beforeOffsetY < -insetTop {
                    indicator.layer.add(refreshEndAnimation(), forKey: Me.ScaleAnimationKey)
                    
                    scrollView.contentOffset.y = beforeOffsetY
                    
                    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                        scrollView.contentOffset.y = -insetTop
                    }) { _ in
                        completionBlock()
                    }
                } else {
                    CATransaction.begin()
                    CATransaction.setCompletionBlock(completionBlock)
                    indicator.layer.add(refreshEndAnimation(), forKey: Me.ScaleAnimationKey)
                    CATransaction.commit()
                }
                
                return
            }
        }
        
        indicator.stopAnimation(false)
    }
    
    fileprivate func refreshEndAnimation() -> CAPropertyAnimation {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.duration = 0.3
        anim.repeatCount = 1
        anim.fromValue = 1
        anim.toValue = 0
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        
        return anim
    }
}
