import Foundation
import UIKit

open class NvRefreshHeader: NvRefreshComponent {
    // 当你的空间太小，以至于无法正常下拉刷新可以设置这个值，会减去下拉的长度
    // If you have too little space to pull down to refresh properly, you can set this value to subtract the length of the pull-down
    open var spacing: CGFloat = 0.0
    // 这个key用来存储上一次下拉刷新成功的时间
    // This key is used to store the time of the last successful pull-down refresh
    public var lastUpdatedTimeKey: String = ""
    // 上一次下拉刷新成功的时间
    // Time when the last drop-down refresh succeeded
    public var lastUpdatedTime: Date {
        (UserDefaults.standard.object(forKey: lastUpdatedTimeKey) as? Date) ?? .init()
    }

    // 忽略多少scrollView的contentInset的top
    // Ignore how much of the top of the contentInset of the scrollView
    open var ignoredScrollViewContentInsetTop: CGFloat = 0.0 {
        didSet {
            self.refresh_y = -self.refresh_height - ignoredScrollViewContentInsetTop
        }
    }

    override open func prepare() {
        super.prepare()
        lastUpdatedTimeKey = NvRefreshConst.HeaderLastUpdatedTimeKey
        refresh_height = NvRefreshConst.HeaderHeight - spacing
    }

    override open func configScrollViewBounce(_ newSuperview: UIView?) {
        super.configScrollViewBounce(newSuperview)
        scrollView?.alwaysBounceVertical = true
        scrollView?.alwaysBounceHorizontal = false
    }

    override open func placeSubviews() {
        super.placeSubviews()
        // 设置y值(当自己的高度发生改变了，肯定要重新调整Y值，所以放到placeSubviews方法中设置y值)
        // Set the y value (If you change your height, you have to readjust the Y value, so put it in the placeSubviews method)
        refresh_y = -refresh_height - ignoredScrollViewContentInsetTop
    }

    override open func updateRefreshState(for lastState: NvRefreshComponent.NvRefreshState) {
        super.updateRefreshState(for: lastState)
        if state == .idel {
            if lastState != .refreshing { return }
            headerEndingAction()
        } else if state == .refreshing {
            headerRefreshingAction()
        }
    }

    override open func scrollViewContentOffsetDidChanged(change: [NSKeyValueChangeKey: Any]?) {
        super.scrollViewContentOffsetDidChanged(change: change)
        if state == .refreshing {
            resetInset()
            return
        }
        guard let currentView = scrollView else { return }
        // 跳转到下一个控制器时，contentInset可能会变
        // The contentInset may change when you jump to the next controller
        originalInset = currentView.refresh_inset
 
        let offsetY = currentView.refresh_offsetY
        // 头部控件刚好出现的offsetY
        // The header control just appears offsetY
        let happenOffsetY = -originalInset.top
        // 如果是向上滚动到看不见头部控件，直接返回
        // If you scroll up until you can't see the header control, go straight back
        if offsetY > happenOffsetY {
            return
        }
        // 普通 和 即将刷新 的临界点
        // The tipping point between normal and about to refresh
        let normal2pullingOffsetY = happenOffsetY - refresh_height
        let percent = (happenOffsetY - offsetY) / refresh_height
        if currentView.isDragging {
            pullingPercent = percent
            if state == .idel && offsetY < normal2pullingOffsetY {
                state = .pulling
            } else if state == .pulling && offsetY >= normal2pullingOffsetY {
                state = .idel
            }
        } else if state == .pulling {
            beginRefreshing()
        } else if percent < 1 {
            pullingPercent = percent
        }
    }

    private func resetInset() {
        guard let currentView = scrollView else { return }
        var insetT = -currentView.refresh_y > originalInset.top ? currentView.refresh_y : originalInset.top
        insetT = insetT > refresh_height + originalInset.top ? refresh_height + originalInset.top : insetT
        insetTDelta = originalInset.top - insetT
        if currentView.refresh_insetT != insetT {
            currentView.refresh_insetT = insetT
        }
    }

    private var insetTDelta: CGFloat = 0
}

extension NvRefreshHeader {
    private func headerRefreshingAction() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: NvRefreshConst.SlowAnimationDuration, animations: {
                if self.scrollView?.panGestureRecognizer.state != .cancelled {
                    let top = self.originalInset.top + self.refresh_height
                    self.scrollView?.refresh_insetT = top
                    var offset = self.scrollView?.contentOffset
                    offset?.y = -top
                    self.scrollView?.setContentOffset(offset ?? .zero, animated: false)
                }
            }, completion: {
                if $0 {
                    self.executeRefreshingCallback()
                }
            })
        }
    }

    private func headerEndingAction() {
        UserDefaults.standard.setValue(Date(), forKey: lastUpdatedTimeKey)
        UserDefaults.standard.synchronize()
        let offset = CGPoint(x: -(self.scrollView?.refresh_insetL ?? 0),
                             y: -self.originalInset.top)
        UIView.animate(withDuration: NvRefreshConst.SlowAnimationDuration, animations: {
            self.scrollView?.refresh_insetT += self.insetTDelta
            self.scrollView?.setContentOffset(offset, animated: false)
            if self.isAutomaticallyChangeAlpha {
                self.alpha = 0
            }
        }, completion: {
            if $0 {
                self.pullingPercent = 0
            }
        })
    }
}
