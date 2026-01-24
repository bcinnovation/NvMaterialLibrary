import Foundation
import UIKit

open class NvRefreshFooter: NvRefreshComponent {
    open var ignoredScrollViewContentInsetBottom: CGFloat = 0.0

    override open func prepare() {
        super.prepare()
        refresh_height = NvRefreshConst.FooterHeight
    }

    override open func configScrollViewBounce(_ newSuperview: UIView?) {
        super.configScrollViewBounce(newSuperview)
        scrollView?.alwaysBounceVertical = true
        scrollView?.alwaysBounceHorizontal = false
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
}
