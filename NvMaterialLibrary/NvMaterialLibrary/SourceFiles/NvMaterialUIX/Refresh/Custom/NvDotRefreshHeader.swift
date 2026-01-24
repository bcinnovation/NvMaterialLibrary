//
//  NvDotRefreshHeader.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/17.
//

import UIKit
import CoreGraphics

open class NvDotRefreshHeader: NvRefreshHeader {

    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()
    
    // MARK: - Configurable properties
    // UIColor(red: 252/255.0, green: 43/255.0, blue: 85/255.0, alpha: 1)
    public var dotColor: UIColor = NvRefreshConst.LabelTextColor {
        didSet {
            [dot1, dot2, dot3].forEach { $0.backgroundColor = dotColor }
        }
    }
    
    public var dotSize: CGFloat = 8 {
        didSet {
            layoutInitialDots()
        }
    }
    
    /// 点之间间距
    public var dotSpacing: CGFloat = 10 {
        didSet {
            layoutInitialDots()
        }
    }
    
    /// 下拉进度 0~1
    public var progress: CGFloat = 0 {
        didSet {
            updateDotsForProgress()
        }
    }
    
    /// 最大缩放值
    public var maxScale: CGFloat = 1.3
    
    open class func header(forTarget target: AnyObject, action: Selector) -> NvRefreshHeader {
        let refreshView = NvDotRefreshHeader(frame: .zero)
        refreshView.configRefreshEvent(target: target, action: action)
        return refreshView
    }
    
    // MARK: - Lifecycle
    open override func prepare() {
        super.prepare()
        [dot1, dot2, dot3].forEach { dot in
            dot.backgroundColor = dotColor
            addSubview(dot)
        }
        layoutInitialDots()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        // 只更新每个 dot 的 center，Header frame 保持不变
        let totalWidth = 3 * dotSize + 2 * dotSpacing
        let startX = (bounds.width - totalWidth) / 2
        let centerY = bounds.height / 2
        let dots = [dot1, dot2, dot3]
        UIView.performWithoutAnimation {
            for (i, dot) in dots.enumerated() {
                dot.center = CGPoint(x: startX + CGFloat(i) * (dotSize + dotSpacing) + dotSize/2,
                                     y: centerY)
            }
        }
    }
    
    private func layoutInitialDots() {
        // 初始化 frame 与 cornerRadius
        let dots = [dot1, dot2, dot3]
        for dot in dots {
            dot.frame = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
            dot.layer.cornerRadius = dotSize / 2
        }
        setNeedsLayout()
    }
    
    private func updateDotsForProgress() {
        let scales: [CGFloat] = [
            min(0.5 + 0.5 * progress, maxScale),
            min(0.5 + 0.5 * progress * 1.2, maxScale),
            min(0.5 + 0.5 * progress * 1.4, maxScale)
        ]
        for (dot, scale) in zip([dot1, dot2, dot3], scales) {
            dot.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    override open func scrollViewContentOffsetDidChanged(change: [NSKeyValueChangeKey: Any]?) {
        super.scrollViewContentOffsetDidChanged(change: change)
        
        guard let scrollView = scrollView else { return }
        let offsetY = scrollView.refresh_offsetY
        let happenOffsetY = -scrollView.refresh_insetT // 头部刚出现的 Y
        let pullDistance = max(happenOffsetY - offsetY, 0)
        let newProgress = min(pullDistance / refresh_height, 1.0)
        
        self.progress = newProgress
    }
    
    // MARK: - Refresh Animation
    open override func beginRefreshing() {
        super.beginRefreshing()
        startAnimation()
    }
    
    open override func endRefreshing() {
        super.endRefreshing()
        stopAnimation()
    }
    
    private func startAnimation() {
        let dots = [dot1, dot2, dot3]
        for (index, dot) in dots.enumerated() {
            let anim = CABasicAnimation(keyPath: "transform.scale")
            anim.fromValue = 1.0
            anim.toValue = self.maxScale
            anim.autoreverses = true
            anim.repeatCount = .infinity
            anim.duration = 0.6
            anim.beginTime = CACurrentMediaTime() + Double(index) * 0.2
            dot.layer.add(anim, forKey: "scale")
        }
    }
    
    private func stopAnimation() {
        [dot1, dot2, dot3].forEach { $0.layer.removeAllAnimations() }
    }
}
