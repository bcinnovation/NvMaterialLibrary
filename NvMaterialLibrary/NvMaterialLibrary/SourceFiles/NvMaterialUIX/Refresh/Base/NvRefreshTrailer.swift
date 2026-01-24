import UIKit
import Foundation

open class NvRefreshTrailer: NvRefreshComponent {
    open var ignoredScrollViewContentInsetRight: CGFloat = 0

    override open func configScrollViewBounce(_ newSuperview: UIView?) {
        super.configScrollViewBounce(newSuperview)
        scrollView?.alwaysBounceVertical = false
        scrollView?.alwaysBounceHorizontal = true
    }

    override open func placeSubviews() {
        super.placeSubviews()
        refresh_height = scrollView?.refresh_height ?? 0
        refresh_width = NvRefreshConst.TrailWidth
    }

    open func endRefreshingWithNoMoreData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.state = .noMoreData
        }
    }

    open func resetNoMoreData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.state = .idel
        }
    }

    override open func updateRefreshState(for lastState: NvRefreshComponent.NvRefreshState) {
        super.updateRefreshState(for: lastState)
        guard let currentView = scrollView else { return }
        // 根据状态来设置属性 / Set properties based on state
        if state == .noMoreData || state == .idel {
            if lastState == .refreshing {
                UIView.animate(withDuration: NvRefreshConst.SlowAnimationDuration, animations: {
                    currentView.refresh_insetR -= self.lastRightDelta
                    if self.isAutomaticallyChangeAlpha { self.alpha = 0 }
                }, completion: {
                    if $0 { self.pullingPercent = 0 }
                })
            }
            let deltaW = widthForContentBreakView()
            if lastState == .refreshing && deltaW > 0 && scrollView?.nv_totalDataCount() != lastRefreshCount {
                currentView.refresh_offsetX = currentView.refresh_offsetX
            }
        } else if state == .refreshing {
            lastRefreshCount = currentView.nv_totalDataCount()
            UIView.animate(withDuration: NvRefreshConst.SlowAnimationDuration, animations: {
                var right = self.refresh_width + self.originalInset.right
                let deltaW = self.widthForContentBreakView()
                if deltaW < 0 { // 如果内容宽度小于view的宽度 / If the content width is less than the width of the view
                    right -= deltaW
                }
                self.lastRightDelta = right - currentView.refresh_insetR
                self.scrollView?.refresh_insetR = right
                // 设置滚动位置 / Set scroll offset
                var offset = currentView.contentOffset
                offset.x = self.happenOffsetX() + self.refresh_width
                currentView.setContentOffset(offset, animated: false)
            }, completion: {
                if $0 { self.executeRefreshingCallback() }
            })
        }
    }

    override open func scrollViewContentOffsetDidChanged(change: [NSKeyValueChangeKey: Any]?) {
        super.scrollViewContentOffsetDidChanged(change: change)
        if state == .refreshing {
            return
        }
        guard let currentView = scrollView else { return }
        originalInset = currentView.refresh_inset

        let currentOffsetX = currentView.refresh_offsetX
        // 尾部控件刚好出现的offsetX / The tail control just appears offsetX
        let happenOffsetX = self.happenOffsetX()
        // 如果是向右滚动到看不见右边控件，直接返回 / If you scroll to the right until you can't see the right control, go right back
        if currentOffsetX <= happenOffsetX {
            return
        }
        let percent = (currentOffsetX - happenOffsetX) / refresh_width
        // 如果已全部加载，仅设置pullingPercent，然后返回 / If it's all loaded, just set pullingPercent and return
        if state == .noMoreData {
            pullingPercent = percent
            return
        }

        if currentView.isDragging {
            pullingPercent = pullingPercent
            // 普通 和 即将刷新 的临界点 / The tipping point between normal and about to refresh
            let normal2pullingOffsetX = happenOffsetX + refresh_width

            if state == .idel && currentOffsetX > normal2pullingOffsetX {
                state = .pulling
            } else if state == .pulling && currentOffsetX <= normal2pullingOffsetX {
                // 转为普通状态 / Turn to normal
                state = .idel
            }
        } else if state == .pulling { // 即将刷新 && 手松开 / About to refresh && hand loose
            // 开始刷新 / Start refresh
            beginRefreshing()
        } else if percent < 1 {
            pullingPercent = percent
        }
    }

    override open func scrollViewContentSizeDidChanged(change: [NSKeyValueChangeKey: Any]?) {
        super.scrollViewContentSizeDidChanged(change: change)
        guard let currentView = scrollView else { return }
        // 内容的宽度 / Width of content
        let contentWidth = currentView.refresh_contentW + ignoredScrollViewContentInsetRight
        // 表格的宽度 / Width of table
        let scrollWidth = currentView.refresh_width - originalInset.left - originalInset
            .right + ignoredScrollViewContentInsetRight
        // 设置位置和尺寸 / Set the location and dimensions
        refresh_x = max(contentWidth, scrollWidth)
    }

    private var lastRefreshCount: Int = 0
    private var lastRightDelta: CGFloat = 0
}

extension NvRefreshTrailer {
    private func happenOffsetX() -> CGFloat {
        let deltaW = widthForContentBreakView()
        if deltaW > 0 {
            return deltaW - originalInset.left
        } else {
            return -originalInset.left
        }
    }

    private func widthForContentBreakView() -> CGFloat {
        guard let currentView = scrollView else { return 0 }
        let w = currentView.frame.size.width - originalInset.right - originalInset.left
        return currentView.contentSize.width - w
    }
}
