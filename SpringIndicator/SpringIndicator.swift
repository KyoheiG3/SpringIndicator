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
    
    private static let RotateAnimationKey = "rotateAnimation"
    private static let ExpandAnimationKey = "expandAnimation"
    private static let ContractAnimationKey = "contractAnimation"
    private static let GroupAnimationKey = "groupAnimation"
    
    private static let StrokeTiming = [0, 0.3, 0.5, 0.7, 1]
    private static let StrokeValues = [0, 0.1, 0.5, 0.9, 1]
    
    private static let DispatchQueueLabelTimer = "SpringIndicator.Timer.Thread"
    private static let timerQueue = dispatch_queue_create(DispatchQueueLabelTimer, DISPATCH_QUEUE_CONCURRENT)
    private static let timerRunLoop = NSRunLoop.currentRunLoop()
    private static let timerPort = NSPort()
    
    public override class func initialize() {
        super.initialize()
        
        dispatch_async(timerQueue) {
            self.timerRunLoop.addPort(self.timerPort, forMode: NSRunLoopCommonModes)
            self.timerRunLoop.run()
        }
    }
    
    public override class func finalize() {
        super.finalize()
        
        timerPort.invalidate()
    }
    
    private var strokeTimer: NSTimer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    private var rotateThreshold = (M_PI / M_PI_2 * 2) - 1
    private var indicatorView: UIView
    private var animationCount: Double = 0
    private var pathLayer: CAShapeLayer? {
        didSet {
            oldValue?.removeAllAnimations()
            oldValue?.removeFromSuperlayer()
        }
    }
    
    /// Start the animation automatically in drawRect.
    @IBInspectable public var animating: Bool = false
    /// Line thickness.
    @IBInspectable public var lineWidth: CGFloat = 3
    /// Line Color. Default is gray.
    @IBInspectable public var lineColor: UIColor = UIColor.grayColor()
    /// Cap style. Options are `round' and `square'. true is `round`. Default is false
    @IBInspectable public var lineCap: Bool = false
    /// Rotation duration. Default is 1.5
    @IBInspectable public var rotateDuration: Double = 1.5
    /// Stroke duration. Default is 0.7
    @IBInspectable public var strokeDuration: Double = 0.7
    
    /// It is called when finished stroke. from subthread.
    public var intervalAnimationsHandler: ((SpringIndicator) -> Void)?
    private var stopAnimationsHandler: ((SpringIndicator) -> Void)?
    
    public override init(frame: CGRect) {
        indicatorView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        super.init(frame: frame)
        indicatorView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        addSubview(indicatorView)
        
        backgroundColor = UIColor.clearColor()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        indicatorView = UIView()
        super.init(coder: aDecoder)
        indicatorView.frame = bounds
        indicatorView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        addSubview(indicatorView)
        
        backgroundColor = UIColor.clearColor()
    }
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if animating {
            startAnimation()
        }
    }
    
    /// During stroke animation is true.
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
    
    private func nextRotatePath(count: Double) -> UIBezierPath {
        animationCount = count
        
        let start = CGFloat(M_PI_2 * (0 - count))
        let end = CGFloat(M_PI_2 * (rotateThreshold - count))
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let radius = max(bounds.width, bounds.height) / 2
        
        let arc = UIBezierPath(arcCenter: center, radius: radius,  startAngle: start, endAngle: end, clockwise: true)
        arc.lineWidth = 0
        
        return arc
    }
    
    private func rotateLayer() -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = lineColor.CGColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = lineCap ? kCALineCapRound : kCALineCapSquare
        
        return shapeLayer
    }
    
    private func nextStrokeLayer(count: Double) -> CAShapeLayer {
        let shapeLayer = rotateLayer()
        shapeLayer.path = nextRotatePath(count).CGPath
        
        return shapeLayer
    }
}

// MARK: - Animation
public extension SpringIndicator {
    /// If start from a state in spread is True.
    public func startAnimation(expand: Bool = false) {
        stopAnimationsHandler = nil
        
        if isSpinning() {
            return
        }
        
        let animation = rotateAnimation(rotateDuration)
        indicatorView.layer.addAnimation(animation, forKey: Me.RotateAnimationKey)
        
        strokeTransaction(expand)
        
        setStrokeTimer(nextStrokeTimer(expand))
    }
    
    /// true is wait for stroke animation.
    public func stopAnimation(waitAnimation: Bool, completion: ((SpringIndicator) -> Void)? = nil) {
        if waitAnimation {
            stopAnimationsHandler = { indicator in
                indicator.stopAnimation(false, completion: completion)
            }
        } else {
            strokeTimer = nil
            stopAnimationsHandler = nil
            indicatorView.layer.removeAllAnimations()
            pathLayer?.strokeEnd = 0
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
    
    private func strokeTransaction(expand: Bool) {
        let count = nextAnimationCount(expand)
        if let layer = pathLayer {
            layer.removeAllAnimations()
            layer.path = nextRotatePath(count).CGPath
            layer.strokeColor = lineColor.CGColor
            layer.lineWidth = lineWidth
        } else {
            let shapeLayer = nextStrokeLayer(count)
            pathLayer = shapeLayer
            indicatorView.layer.addSublayer(shapeLayer)
        }
        
        let animation = nextStrokeAnimation(expand)
        let animationKey = nextAnimationKey(expand)
        pathLayer?.addAnimation(animation, forKey: animationKey)
    }
    
    // MARK: stroke properties
    private func nextStrokeTimer(expand: Bool) -> NSTimer {
        let animationKey = nextAnimationKey(expand)
        
        if expand {
            return createStrokeTimer(timeInterval: strokeDuration, userInfo: animationKey, repeats: false)
        } else {
            return createStrokeTimer(timeInterval: strokeDuration * 2, userInfo: animationKey, repeats: true)
        }
    }
    
    private func nextAnimationKey(expand: Bool) -> String {
        return expand ? Me.ContractAnimationKey : Me.GroupAnimationKey
    }
    
    private func nextAnimationCount(expand: Bool) -> Double {
        return expand ? 0 : incrementAnimationCount()
    }
    
    private func nextStrokeAnimation(expand: Bool) -> CAAnimation {
        return expand ? contractAnimation(strokeDuration) : groupAnimation(strokeDuration)
    }
    
    // MARK: animations
    private func rotateAnimation(duration: CFTimeInterval) -> CAPropertyAnimation {
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.duration = duration
        anim.repeatCount = HUGE
        anim.fromValue = -(M_PI + M_PI_4)
        anim.toValue = M_PI - M_PI_4
        anim.removedOnCompletion = false
        
        return anim
    }
    
    private func groupAnimation(duration: CFTimeInterval) -> CAAnimationGroup {
        let expand = expandAnimation(duration)
        expand.beginTime = 0
        
        let contract = contractAnimation(duration)
        contract.beginTime = duration
        
        let group = CAAnimationGroup()
        group.animations = [expand, contract]
        group.duration = duration * 2
        group.fillMode = kCAFillModeForwards
        group.removedOnCompletion = false
        
        return group
    }
    
    private func contractAnimation(duration: CFTimeInterval) -> CAPropertyAnimation {
        let anim = CAKeyframeAnimation(keyPath: "strokeStart")
        anim.duration = duration
        anim.keyTimes = Me.StrokeTiming
        anim.values = Me.StrokeValues
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        
        return anim
    }
    
    private func expandAnimation(duration: CFTimeInterval) -> CAPropertyAnimation {
        let anim = CAKeyframeAnimation(keyPath: "strokeEnd")
        anim.duration = duration
        anim.keyTimes = Me.StrokeTiming
        anim.values = Me.StrokeValues
        
        return anim
    }
}

// MARK: - Timer
internal extension SpringIndicator {
    private func createStrokeTimer(timeInterval ti: NSTimeInterval, userInfo: AnyObject?, repeats yesOrNo: Bool) -> NSTimer {
        return NSTimer(timeInterval: ti, target: self, selector: Selector("onStrokeTimer:"), userInfo: userInfo, repeats: yesOrNo)
    }
    
    private func setStrokeTimer(timer: NSTimer) {
        strokeTimer = timer
        Me.timerRunLoop.addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    func onStrokeTimer(sender: AnyObject) {
        stopAnimationsHandler?(self)
        intervalAnimationsHandler?(self)
        
        if isSpinning() == false {
            return
        }
        
        if let timer = sender as? NSTimer, key = timer.userInfo as? String where key == Me.ContractAnimationKey {
            let timer = createStrokeTimer(timeInterval: strokeDuration * 2, userInfo: Me.GroupAnimationKey, repeats: true)
            
            setStrokeTimer(timer)
        }
        
        strokeTransaction(false)
    }
}

// MARK: - Stroke
public extension SpringIndicator {
    /// between 0.0 and 1.0.
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
            let shapeLayer = nextStrokeLayer(0)
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
public extension SpringIndicator {
    public class Refresher: UIControl {
        private typealias Me = Refresher
        
        private static let ObserverOffsetKeyPath = "contentOffset"
        private static let ScaleAnimationKey = "scaleAnimation"
        private static let DefaultContentHeight: CGFloat = 60
        
        private var RefresherContext = UInt8()
        private var initialInsetTop: CGFloat = 0
        public let indicator = SpringIndicator(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        public private(set) var refreshing: Bool = false
        public private(set) var targetView: UIScrollView?
        
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
        
        public override func layoutSubviews() {
            super.layoutSubviews()
            
            backgroundColor = UIColor.clearColor()
            userInteractionEnabled = false
            autoresizingMask = [.FlexibleWidth, .FlexibleBottomMargin]
            
            if let superview = superview {
                frame.size.height = Me.DefaultContentHeight
                frame.size.width = superview.bounds.width
                center.x = superview.center.x
                
                if let scrollView = superview as? UIScrollView {
                    initialInsetTop = scrollView.contentInset.top
                }
            }
        }
        
        public override func willMoveToSuperview(newSuperview: UIView!) {
            super.willMoveToSuperview(newSuperview)
            
            targetView = newSuperview as? UIScrollView
            addObserver()
        }
        
        public override func didMoveToSuperview() {
            super.didMoveToSuperview()
            
            layoutIfNeeded()
        }
        
        public override func removeFromSuperview() {
            removeObserver()
            super.removeFromSuperview()
        }
        
        weak var target: AnyObject?
        public override func addTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) {
            super.addTarget(target, action: action, forControlEvents: controlEvents)
            
            self.target = target
        }
        
        public override func removeTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) {
            super.removeTarget(target, action: action, forControlEvents: controlEvents)
            
            self.target = nil
        }
        
        public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
            switch context {
            case &RefresherContext:
                if let scrollView = object as? UIScrollView {
                    if target == nil {
                        removeObserver()
                        targetView = nil
                        return
                    }
                    
                    if bounds.height <= 0 {
                        return
                    }
                    
                    frame.origin.y = scrollOffset(scrollView)
                    
                    if indicator.isSpinning() {
                        return
                    }
                    
                    if refreshing && scrollView.dragging == false {
                        refreshStart(scrollView)
                        return
                    }
                    
                    let ratio = scrollRatio(scrollView)
                    refreshing = ratio >= 1
                    
                    indicator.strokeRatio(ratio)
                    rotateRatio(ratio)
                }
            default:
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            }
        }
        
        private func setupIndicator() {
            indicator.lineWidth = 2
            indicator.rotateDuration = 1
            indicator.strokeDuration = 0.5
            indicator.center = center
            indicator.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
            addSubview(indicator)
        }
        
        private func addObserver() {
            targetView?.addObserver(self, forKeyPath: Me.ObserverOffsetKeyPath, options: .New, context: &RefresherContext)
        }
        
        private func removeObserver() {
            targetView?.removeObserver(self, forKeyPath: Me.ObserverOffsetKeyPath, context: &RefresherContext)
        }
        
        private func notObserveBlock(block: (() -> Void)) {
            removeObserver()
            block()
            addObserver()
        }
        
        private func scrollOffset(scrollView: UIScrollView) -> CGFloat {
            var offsetY = scrollView.contentOffset.y
            offsetY += initialInsetTop
            
            return offsetY
        }
        
        private func scrollRatio(scrollView: UIScrollView) -> CGFloat {
            var offsetY = scrollOffset(scrollView)
            
            offsetY += frame.size.height - indicator.frame.size.height
            if offsetY > 0 {
                offsetY = 0
            }
            
            return abs(offsetY / bounds.height)
        }
        
        private func rotateRatio(ratio: CGFloat) {
            let value = max(min(ratio, 1), 0)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            indicator.indicatorView.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI - M_PI_4) * value, 0, 0, 1)
            CATransaction.commit()
        }
    }
}

// MARK: - Refresher start
private extension SpringIndicator.Refresher {
    private func refreshStart(scrollView: UIScrollView) {
        sendActionsForControlEvents(.ValueChanged)
        indicator.layer.addAnimation(refreshStartAnimation(), forKey: Me.ScaleAnimationKey)
        indicator.startAnimation(true)
        
        let insetTop = initialInsetTop + bounds.height
        
        notObserveBlock {
            scrollView.contentInset.top = insetTop
        }
        
        scrollView.contentOffset.y -= insetTop - initialInsetTop
    }
    
    private func refreshStartAnimation() -> CAPropertyAnimation {
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
        
        if let scrollView = superview as? UIScrollView {
            let insetTop: CGFloat
            
            if scrollView.superview?.superview == nil {
                insetTop = 0
            } else {
                insetTop = initialInsetTop
            }
            
            if scrollView.contentInset.top > insetTop {
                let completionBlock: (() -> Void) = {
                    self.indicator.stopAnimation(false) { indicator in
                        indicator.layer.removeAnimationForKey(Me.ScaleAnimationKey)
                    }
                }
                
                let beforeOffsetY = scrollView.contentOffset.y
                scrollView.contentInset.top = insetTop
                
                if beforeOffsetY < -insetTop {
                    indicator.layer.addAnimation(refreshEndAnimation(), forKey: Me.ScaleAnimationKey)
                    
                    scrollView.contentOffset.y = beforeOffsetY
                    
                    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .AllowUserInteraction, animations: {
                        scrollView.contentOffset.y = -insetTop
                        }) { _ in
                            completionBlock()
                    }
                } else {
                    CATransaction.begin()
                    CATransaction.setCompletionBlock(completionBlock)
                    indicator.layer.addAnimation(refreshEndAnimation(), forKey: Me.ScaleAnimationKey)
                    CATransaction.commit()
                }
                
                return
            }
        }
        
        indicator.stopAnimation(false)
    }
    
    private func refreshEndAnimation() -> CAPropertyAnimation {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.duration = 0.3
        anim.repeatCount = 1
        anim.fromValue = 1
        anim.toValue = 0
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        
        return anim
    }
}
