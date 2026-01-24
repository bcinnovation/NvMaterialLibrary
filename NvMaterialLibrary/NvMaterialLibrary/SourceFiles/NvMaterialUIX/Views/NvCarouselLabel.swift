//
//  NvCarouselLabel.swift
//  MYVideo
//
//  Created by meishe on 2023/7/7.
//

import UIKit

open class NvCarouselLabel: UILabel {

    private var backupTextColor: UIColor?
    private let scrollView = UIScrollView()
    private var timer: Timer?
    private var animateLableWidth: CGFloat = 0

    private func copyLabel() -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = textColor
        label.font = font
        label.textAlignment = .left
        return label
    }
    
    public func startAnimate() {
        guard let labelText = text else { return }
        let size = stringSize(text: labelText, font: font)
        if size.width < frame.width {
            return
        }
        if !scrollView.subviews.isEmpty {
            return
        }
        scrollView.frame = bounds
        addSubview(scrollView)
        animateLableWidth = size.width + 10
        let firstLable = copyLabel()
        firstLable.frame = CGRect(x: 0, y: 0, width: animateLableWidth, height: bounds.height)
        scrollView.addSubview(firstLable)
        let secLable = copyLabel()
        secLable.frame = CGRect(x: animateLableWidth, y: 0, width: animateLableWidth, height: bounds.height)
        scrollView.addSubview(secLable)
        scrollView.contentSize = CGSize(width: animateLableWidth * 2, height: bounds.height)
        
        backupTextColor = textColor
        textColor = .clear
        
        if timer != nil {
            timer?.invalidate()
        }
        let nTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.countDown(timer: timer)
        }
        countDown(timer: nTimer)
        timer = nTimer
    }
    
    private func countDown(timer: Timer) {
        let stepWidth: CGFloat = 1
        
        let offsetX = scrollView.contentOffset.x
        
        let maxOffsetX = scrollView.contentSize.width - frame.width
        var targetOffsetX = offsetX + stepWidth
        if targetOffsetX > maxOffsetX {
            if offsetX > animateLableWidth {
                scrollView.contentOffset = CGPoint(x: offsetX - animateLableWidth, y: 0)
            }
            targetOffsetX = offsetX - animateLableWidth + stepWidth
        }
        let timeInterval = timer.timeInterval
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(timeInterval)
        UIView.setAnimationCurve(.linear)
        scrollView.setContentOffset(CGPoint(x: targetOffsetX, y: 0), animated: false)
        UIView.commitAnimations()
    }
    
    public func stopAnimate() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        scrollView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        scrollView.removeFromSuperview()
        if let color = backupTextColor {
            textColor = color
            backupTextColor = nil
        }
    }

    public func stringSize(text: String, font: UIFont) -> CGSize {
        let resultSize = text.boundingRect(with: CGSize(width: 1000, height: 30),
                                      options: NSStringDrawingOptions(rawValue: NSStringDrawingOptions
                                          .usesLineFragmentOrigin.rawValue | NSStringDrawingOptions.usesFontLeading
                                          .rawValue | NSStringDrawingOptions.truncatesLastVisibleLine.rawValue),
                                      attributes: [NSAttributedString.Key.font: font], context: nil).size
        return resultSize
    }
}
