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
    private typealias Me = SpringIndicator
    
    private static let LotateAnimationKey = "rotateAnimation"
    private static let ExpandAnimationKey = "expandAnimation"
    private static let ContractAnimationKey = "contractAnimation"
    private static let GroupAnimationKey = "groupAnimation"
    
    private static let StrokeTiming = [0, 0.3, 0.5, 0.7, 1]
    private static let StrokeValues = [0, 0.1, 0.5, 0.9, 1]
    
    private static let DispatchQueueLabelTimer = "SpringIndicator.Timer.Thread"
    private static let timerQueue = dispatch_queue_create(DispatchQueueLabelTimer, DISPATCH_QUEUE_CONCURRENT)
    
    public class Refresher: UIControl {
        private var RefresherContext = ""
        private let ObserverOffsetKeyPath = "contentOffset"
        private let ScaleAnimationKey = "scaleAnimation"
        private let DefaultContentHeight: CGFloat = 60
        
        private var initialInsetTop: CGFloat = 0
        public private(set) var indicator = SpringIndicator(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        public private(set) var refreshing: Bool = false
        public var targetView: UIScrollView?
        public var refreshingInsetTop: CGFloat {
            return initialInsetTop + (refreshing ? bounds.height : 0)
        }
        
        deinit {
            indicator.stopAnimation(false)
        }
        
        public convenience init() {
            self.init(frame: CGRect.zeroRect)
        }
        
        override init(var frame: CGRect) {
            super.init(frame: frame)
            
            setupIndicator()
        }
        
        public required init(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            setupIndicator()
        }
        
        public override func layoutSubviews() {
            super.layoutSubviews()
            
            backgroundColor = UIColor.clearColor()
            userInteractionEnabled = false
            autoresizingMask = .FlexibleWidth | .FlexibleBottomMargin
            
            if let superview = superview {
                frame.size.height = DefaultContentHeight
                frame.size.width = superview.bounds.width
                center.x = superview.center.x
                
                if let scrollView = superview as? UIScrollView {
                    initialInsetTop = scrollView.contentInset.top
                }
            }
        }
        
        public override func willMoveToSuperview(newSuperview: UIView!) {
            if let scrollView = newSuperview as? UIScrollView {
                addObserver(scrollView)
            }
        }
        
        weak var target: AnyObject?
        public override func addTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) {
            super.addTarget(target, action: action, forControlEvents: controlEvents)
            
            self.target = target
        }
        
        public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
            if let scrollView = object as? UIScrollView {
                if target == nil {
                    targetView?.removeObserver(self, forKeyPath: ObserverOffsetKeyPath, context: &RefresherContext)
                    targetView = nil
                    
                    return
                }
                
                if scrollView.superview?.superview == nil {
                    return
                }
                
                if bounds.height <= 0 {
                    return
                }
                
                var offsetY = scrollView.contentOffset.y
                if refreshing == true {
                    offsetY += initialInsetTop
                } else {
                    offsetY += scrollView.contentInset.top
                }
                frame.origin.y = offsetY
                
                if allTargets().count <= 0 {
                    return
                }
                
                if indicator.isSpinning() {
                    return
                }
                
                if refreshing && scrollView.dragging == false {
                    refreshStart(scrollView)
                    return
                }
                
                offsetY += frame.size.height - indicator.frame.size.height
                if offsetY > 0 {
                    offsetY = 0
                }
                
                let ratio = abs(offsetY / bounds.height)
                if ratio >= 1 {
                    refreshing = true
                } else {
                    refreshing = false
                }
                
                indicator.strokeRatio(ratio)
            }
        }
        
        private func setupIndicator() {
            indicator.lineWidth = 2
            indicator.lotateDuration = 1
            indicator.strokeDuration = 0.5
            indicator.center = center
            indicator.autoresizingMask = .FlexibleLeftMargin | .FlexibleRightMargin | .FlexibleTopMargin | .FlexibleBottomMargin
            addSubview(indicator)
        }
    }
    
    private var strokeTimer: NSTimer?
    private var rotateThreshold = (M_PI / M_PI_2 * 2) - 1
    private var indicatorView: UIView
    private var animationCount: Double = 0
    private var pathLayer: CAShapeLayer? {
        willSet {
            self.pathLayer?.removeAllAnimations()
            self.pathLayer?.removeFromSuperlayer()
        }
    }
    
    @IBInspectable public var animating: Bool = false
    @IBInspectable public var lineWidth: CGFloat = 3
    @IBInspectable public var lineColor: UIColor = UIColor.grayColor()
    @IBInspectable public var lotateDuration: Double = 1.5
    @IBInspectable public var strokeDuration: Double = 0.7
    
    /// It is called when finished stroke. from subthread.
    public var intervalAnimationsHandler: ((SpringIndicator) -> Void)?
    private var stopAnimationsHandler: ((SpringIndicator) -> Void)?
    
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
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if animating {
            startAnimation()
        }
    }
    
    public func isSpinning() -> Bool {
        return pathLayer?.animationForKey(Me.ContractAnimationKey) != nil || pathLayer?.animationForKey(Me.GroupAnimationKey) != nil
    }
    
    private func incrementAnimationCount() -> Double {
        animationCount++
        
        if animationCount > rotateThreshold {
            animationCount = 0
        }
        
        return animationCount
    }
    
    private func rotateLayer(count: Double) -> CAShapeLayer {
        animationCount = count
        
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
}

public extension SpringIndicator.Refresher {
    public func startRefreshing(sendActions: Bool = false) {
        if sendActions {
            sendActionsForControlEvents(.ValueChanged)
        }
        
        indicator.layer.addAnimation(refreshAnimation(), forKey: ScaleAnimationKey)
        indicator.startAnimation()
    }
    
    public func endRefreshing() {
        refreshing = false
        
        if let scrollView = superview as? UIScrollView {
            var insetTop: CGFloat = 0
            
            if scrollView.superview?.superview == nil {
                insetTop = refreshingInsetTop - initialInsetTop
            } else {
                insetTop = refreshingInsetTop
            }
            
            if scrollView.contentInset.top > insetTop {
                scrollView.contentInset.top = insetTop
            }
        }
        
        indicator.stopAnimation(true)
    }
}

private extension SpringIndicator.Refresher {
    private func addObserver(scrollView: UIScrollView) {
        if targetView == nil {
            scrollView.addObserver(self, forKeyPath: ObserverOffsetKeyPath, options: .New, context: &RefresherContext)
            targetView = scrollView
        }
    }
    
    private func refreshStart(scrollView: UIScrollView) {
        let insetTop = refreshingInsetTop
        
        refreshing = false
        scrollView.contentInset.top = insetTop
        refreshing = true
        
        sendActionsForControlEvents(.ValueChanged)
        indicator.layer.addAnimation(refreshAnimation(), forKey: ScaleAnimationKey)
        indicator.startAnimation(expand: true)
        
        scrollView.contentOffset.y -= scrollView.contentInset.top - initialInsetTop
        frame.origin.y = initialInsetTop + scrollView.contentOffset.y - bounds.height
    }
    
    private func refreshAnimation() -> CAPropertyAnimation {
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

// MARK: - Animation
public extension SpringIndicator {
    public func startAnimation(expand: Bool = false) {
        stopAnimationsHandler = nil
        
        if isSpinning() {
            return
        }
        
        indicatorView.layer.addAnimation(lotateAnimation(), forKey: Me.LotateAnimationKey)
        
        nextAnimation(expand)
        
        let timer: NSTimer
        if expand {
            timer = createTimer(timeInterval: strokeDuration, userInfo: Me.ContractAnimationKey, repeats: false)
        } else {
            timer = createTimer(timeInterval: strokeDuration * 2, userInfo: Me.GroupAnimationKey, repeats: true)
        }
        
        setStrokeTimer(timer)
    }
    
    public func stopAnimation(waitAnimation: Bool, completion: ((SpringIndicator) -> Void)? = nil) {
        if waitAnimation {
            stopAnimationsHandler = { indicator in
                indicator.stopAnimation(false, completion: completion)
            }
        } else {
            strokeTimer?.invalidate()
            strokeTimer = nil
            
            stopAnimationsHandler = nil
            indicatorView.layer.removeAllAnimations()
            pathLayer?.removeAllAnimations()
            pathLayer = nil
            
            if NSThread.currentThread().isMainThread {
                completion?(self)
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    completion?(self)
                }
            }
        }
    }
    
    private func nextAnimation(expand: Bool) {
        var count: Double = 0
        if expand == false {
            count = incrementAnimationCount()
        }
        
        let shapeLayer = rotateLayer(count)
        pathLayer = shapeLayer
        indicatorView.layer.addSublayer(shapeLayer)
        
        nextTransaction(expand)
    }
    
    private func nextTransaction(expand: Bool) {
        if expand {
            pathLayer?.addAnimation(contractAnimation(), forKey: Me.ContractAnimationKey)
        } else {
            pathLayer?.addAnimation(groupAnimation(), forKey: Me.GroupAnimationKey)
        }
    }
    
    private func lotateAnimation() -> CAPropertyAnimation {
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.duration = lotateDuration
        anim.repeatCount = HUGE
        anim.fromValue = 0
        anim.toValue = M_PI * 2
        
        return anim
    }
    
    private func groupAnimation() -> CAAnimationGroup {
        let expand = expandAnimation()
        expand.beginTime = 0
        
        let contract = contractAnimation()
        contract.beginTime = strokeDuration
        
        let group = CAAnimationGroup()
        group.animations = [expand, contract]
        group.duration = strokeDuration * 2
        group.fillMode = kCAFillModeForwards
        group.removedOnCompletion = false
        
        return group
    }
    
    private func contractAnimation() -> CAPropertyAnimation {
        let anim = CAKeyframeAnimation(keyPath: "strokeStart")
        anim.duration = strokeDuration
        anim.keyTimes = Me.StrokeTiming
        anim.values = Me.StrokeValues
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        
        return anim
    }
    
    private func expandAnimation() -> CAPropertyAnimation {
        let anim = CAKeyframeAnimation(keyPath: "strokeEnd")
        anim.duration = strokeDuration
        anim.keyTimes = Me.StrokeTiming
        anim.values = Me.StrokeValues
        
        return anim
    }
}

// MARK: - Timer
internal extension SpringIndicator {
    private func createTimer(timeInterval ti: NSTimeInterval, userInfo: AnyObject?, repeats yesOrNo: Bool) -> NSTimer {
        return NSTimer(timeInterval: ti, target: self, selector: Selector("onStrokeTimer:"), userInfo: userInfo, repeats: yesOrNo)
    }
    
    private func setStrokeTimer(timer: NSTimer) {
        strokeTimer?.invalidate()
        strokeTimer = timer
        
        dispatch_async(Me.timerQueue) {
            NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            NSRunLoop.currentRunLoop().run()
        }
    }
    
    func onStrokeTimer(timer: NSTimer) {
        stopAnimationsHandler?(self)
        intervalAnimationsHandler?(self)
        
        if isSpinning() == false {
            return
        }
        
        if (timer.userInfo as? String) == Me.ContractAnimationKey {
            let timer = createTimer(timeInterval: strokeDuration * 2, userInfo: Me.GroupAnimationKey, repeats: true)
            
            setStrokeTimer(timer)
        }
        
        nextAnimation(false)
    }
}

public extension SpringIndicator {
    public func strokeRatio(ratio: CGFloat) {
        if ratio <= 0 {
            pathLayer = nil
        } else if ratio >= 1 {
            strokeValue(1)
        } else {
            strokeValue(ratio)
        }
    }
    
    private func strokeValue(value: CGFloat) {
        if pathLayer == nil {
            let shapeLayer = rotateLayer(0)
            indicatorView.layer.addSublayer(shapeLayer)
            
            pathLayer = shapeLayer
        }
        
        let anim = stroke(fromValue: 0, toValue: value)
        pathLayer?.addAnimation(anim, forKey: Me.ExpandAnimationKey)
    }
    
    private func stroke(#fromValue: CGFloat, toValue: CGFloat) -> CAPropertyAnimation? {
        let anim = CAKeyframeAnimation(keyPath: "strokeEnd")
        anim.duration = 0
        anim.repeatCount = HUGE
        anim.keyTimes = [0, 0]
        anim.values = [fromValue, toValue]
        anim.fillMode = kCAFillModeBackwards
        return anim
    }
}
