//
//  RefreshIndicator.swift
//  SpringIndicator
//
//  Created by Kyohei Ito on 2017/09/22.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

import UIKit

open class RefreshIndicator: UIControl {
    deinit {
        stopIndicatorAnimation()
    }

    private let defaultContentHeight: CGFloat = 60
    private var refreshContext = UInt8()
    private var initialInsetTop: CGFloat = 0
    private weak var target: AnyObject?
    private var targetView: UIScrollView? {
        willSet {
            removeObserver()
        }
        didSet {
            addObserver()
        }
    }

    public let indicator = SpringIndicator(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    public private(set) var isRefreshing: Bool = false

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

    private func setupIndicator() {
        indicator.lineWidth = 2
        indicator.rotationDuration = 1
        indicator.center = center
        indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        addSubview(indicator)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        backgroundColor = UIColor.clear
        isUserInteractionEnabled = false

        if let scrollView = superview as? UIScrollView {
            autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            frame.size.height = defaultContentHeight
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

    open override func addTarget(_ target: Any?, action: Selector, for controlEvent: UIControl.Event) {
        super.addTarget(target, action: action, for: controlEvent)

        self.target = target as AnyObject?
    }

    open override func removeTarget(_ target: Any?, action: Selector?, for controlEvent: UIControl.Event) {
        super.removeTarget(target, action: action, for: controlEvent)

        self.target = nil
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = object as? UIScrollView, context == &refreshContext else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }

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

        if indicator.isSpinning {
            return
        }

        if isRefreshing && scrollView.isDragging == false {
            beginRefreshing(with: scrollView)
            return
        }

        let ratio = scrollRatio(scrollView)
        isRefreshing = ratio >= 1
        indicator.strokeRatio(ratio)
        rotationRatio(ratio)
    }

    private func addObserver() {
        targetView?.addObserver(self, forKeyPath: "contentOffset", options: .new, context: &refreshContext)
    }

    private func removeObserver() {
        targetView?.removeObserver(self, forKeyPath: "contentOffset", context: &refreshContext)
    }

    private func withoutObserve(_ block: (() -> Void)) {
        removeObserver()
        block()
        addObserver()
    }

    private func scrollOffset(_ scrollView: UIScrollView) -> CGFloat {
        var offsetY = scrollView.contentOffset.y
        if #available(iOS 11.0, tvOS 11.0, *) {
            offsetY += initialInsetTop + scrollView.safeAreaInsets.top
        } else {
            offsetY += initialInsetTop
        }

        return offsetY
    }

    private func scrollRatio(_ scrollView: UIScrollView) -> CGFloat {
        var offsetY = scrollOffset(scrollView)

        offsetY += frame.size.height - indicator.frame.size.height
        if offsetY > 0 {
            offsetY = 0
        }

        return abs(offsetY / bounds.height)
    }

    private func rotationRatio(_ ratio: CGFloat) {
        let value = max(min(ratio, 1), 0)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        indicator.indicatorView.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi - Double.pi_4) * value, 0, 0, 1)
        CATransaction.commit()
    }
}

// MARK: - Refresh
extension RefreshIndicator {
    // MARK: begin
    private func beginRefreshing(with scrollView: UIScrollView) {
        sendActions(for: .valueChanged)
        indicator.layer.add(beginAnimation(), for: .scale)
        startIndicatorAnimation()

        let insetTop = initialInsetTop + bounds.height

        withoutObserve {
            scrollView.contentInset.top = insetTop
        }

        scrollView.contentOffset.y -= insetTop - initialInsetTop
    }

    // MARK: end
    /// Must be explicitly called when the refreshing has completed
    public func endRefreshing() {
        isRefreshing = false

        guard let scrollView = targetView else {
            stopIndicatorAnimation()
            return
        }

        let insetTop: CGFloat
        let safeAreaTop: CGFloat
        if #available(iOS 11.0, tvOS 11.0, *) {
            safeAreaTop = scrollView.safeAreaInsets.top
        } else {
            safeAreaTop = 0
        }

        if scrollView.superview?.superview == nil {
            insetTop = 0
        } else {
            insetTop = initialInsetTop + safeAreaTop
        }

        if scrollView.contentInset.top + safeAreaTop > insetTop {
            let cachedOffsetY = scrollView.contentOffset.y
            scrollView.contentInset.top = insetTop - safeAreaTop

            if cachedOffsetY < -insetTop {
                indicator.layer.add(endAnimation(), for: .scale)
                scrollView.contentOffset.y = cachedOffsetY

                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                    scrollView.contentOffset.y = -insetTop
                }) { _ in
                    self.stopIndicatorAnimation()
                }
            } else {
                CATransaction.begin()
                CATransaction.setCompletionBlock(stopIndicatorAnimation)
                indicator.layer.add(endAnimation(), for: .scale)
                CATransaction.commit()
            }
        } else {
            stopIndicatorAnimation()
        }
    }
}

// MARK: - Animation
extension RefreshIndicator {
    // MARK: for Begin
    private func beginAnimation() -> CAPropertyAnimation {
        let anim = CABasicAnimation(key: .scale)
        anim.duration = 0.1
        anim.repeatCount = 1
        anim.autoreverses = true
        anim.fromValue = 1
        anim.toValue = 1.3
        anim.timingFunction = CAMediaTimingFunction(name: .easeIn)

        return anim
    }

    // MARK: for End
    private func endAnimation() -> CAPropertyAnimation {
        let anim = CABasicAnimation(key: .scale)
        anim.duration = 0.3
        anim.repeatCount = 1
        anim.fromValue = 1
        anim.toValue = 0
        anim.timingFunction = CAMediaTimingFunction(name: .easeIn)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        return anim
    }
}
