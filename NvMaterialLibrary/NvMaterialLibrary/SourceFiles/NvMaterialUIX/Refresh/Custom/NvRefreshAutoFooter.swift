import UIKit
import Foundation

open class NvRefreshAutoFooter: NvRefreshFooter {
    public var labelLeftInset: CGFloat = 0
    public private(set) weak var stateLabel: UILabel?
    public private(set) weak var arrowView: UIImageView?
    public private(set) weak var loadingView: UIActivityIndicatorView?

    open class func footer(forTarget target: AnyObject, action: Selector) -> NvRefreshAutoFooter {
        let refreshView = NvRefreshAutoFooter(frame: .zero)
        refreshView.configRefreshEvent(target: target, action: action)
        refreshView.stateLabel?.text = refreshView.stateTitles[refreshView.state.rawValue]
        return refreshView
    }

    override open func prepare() {
        super.prepare()
        // 初始化控件
        initCustomControl()
        labelLeftInset = NvRefreshConst.LabelLeftInset
        // 初始化文字
        setTitle(NvMaterialUIXEnvs.localizedString(key: NvRefreshConst.FooterIdleText, comment: ""), state: .idel)
        setTitle(NvMaterialUIXEnvs.localizedString(key: NvRefreshConst.FooterPullingText, comment: ""), state: .pulling)
        setTitle(NvMaterialUIXEnvs.localizedString(key: NvRefreshConst.FooterRefreshingText, comment: ""), state: .refreshing)
        setTitle(NvMaterialUIXEnvs.localizedString(key: NvRefreshConst.FooterNoMoreDataText, comment: ""), state: .noMoreData)
        // 配置加载
        loadingView?.hidesWhenStopped = true
        if #available(iOS 13.0, *) {
            self.loadingView?.style = .medium
        } else {
            loadingView?.style = .gray
        }
    }

    override open func placeSubviews() {
        super.placeSubviews()
        if stateLabel?.constraints.isEmpty != true {
            return
        }
        stateLabel?.frame = bounds
        // 箭头的中心点
        var arrowCenterX = refresh_width * 0.5
        if stateLabel?.isHidden == false {
            let stateWidth = stateLabel?.refresh_textWidth() ?? 0.0
            arrowCenterX -= labelLeftInset + stateWidth * 0.5
        }
        let arrowCenterY = refresh_height * 0.5
        let arrowCenter = CGPoint(x: arrowCenterX, y: arrowCenterY)

        // 箭头
        if arrowView?.constraints.isEmpty == true {
            arrowView?.refresh_size = arrowView?.image?.size ?? .zero
            arrowView?.center = arrowCenter
        }

        // 圈圈
        if loadingView?.constraints.isEmpty == true {
            loadingView?.center = arrowCenter
        }
        arrowView?.tintColor = stateLabel?.textColor
    }

    override open func configScrollViewBounce(_ newSuperview: UIView?) {
        super.configScrollViewBounce(newSuperview)
        scrollViewContentSizeDidChanged(change: nil)
    }

    override open func scrollViewContentOffsetDidChanged(change: [NSKeyValueChangeKey: Any]?) {
        super.scrollViewContentOffsetDidChanged(change: change)
        guard let currentView = scrollView, state != .refreshing else { return }
        originalInset = currentView.refresh_inset
        let currentOffsetY = currentView.refresh_offsetY
        let happenOffsetY = happenOffsetY()
        if currentOffsetY <= happenOffsetY { return }
        let percent = (currentOffsetY - happenOffsetY) / refresh_height
        if state == .noMoreData {
            pullingPercent = percent
            return
        }
        if currentView.isDragging {
            pullingPercent = percent
            let normal2pullingOffsetY = happenOffsetY + refresh_height
            if state == .idel && currentOffsetY > normal2pullingOffsetY {
                state = .pulling
            } else if state == .pulling && currentOffsetY <= normal2pullingOffsetY {
                state = .idel
            }
        } else if state == .pulling {
            beginRefreshing()
        } else if percent < 1 {
            pullingPercent = percent
        }
    }

    override open func scrollViewContentSizeDidChanged(change: [NSKeyValueChangeKey: Any]?) {
        super.scrollViewContentSizeDidChanged(change: change)
        guard let currentView = scrollView else { return }
        let size = change?[NSKeyValueChangeKey.newKey] as? CGSize ?? .zero
        var contentHeight = size.height == 0 ? currentView.refresh_contentH : size.height
        contentHeight += ignoredScrollViewContentInsetBottom
        let scrollHeight = currentView.refresh_height - originalInset.top - originalInset
            .bottom + ignoredScrollViewContentInsetBottom
        let y = max(contentHeight, scrollHeight)
        if refresh_y != y {
            refresh_y = y
        }
    }

    override open func updateRefreshState(for lastState: NvRefreshComponent.NvRefreshState) {
        super.updateRefreshState(for: lastState)
        guard let currentView = scrollView else { return }
        stateLabel?.text = stateTitles[state.rawValue]

        if state == .idel {
            if lastState == .refreshing {
                arrowView?.transform = CGAffineTransform(rotationAngle: 0.000001 - .pi)
                UIView.animate(withDuration: NvRefreshConst.SlowAnimationDuration, animations: {
                    currentView.refresh_insetB -= self.lastBottomDelta
                    self.loadingView?.alpha = 0
                    if self.isAutomaticallyChangeAlpha { self.alpha = 0 }
                }, completion: {
                    if $0 {
                        self.pullingPercent = 0
                        if self.state != .idel { return }
                        self.loadingView?.alpha = 1.0
                        self.loadingView?.stopAnimating()
                        self.arrowView?.isHidden = false
                    }
                })
            } else {
                arrowView?.isHidden = false
                loadingView?.stopAnimating()
                UIView.animate(withDuration: NvRefreshConst.FastAnimationDuration, animations: {
                    self.arrowView?.transform = CGAffineTransform(rotationAngle: 0.000001 - .pi)
                })
            }
            let deltaH = heightForContentBreakView()
            if lastState == .refreshing && deltaH > 0 && currentView.nv_totalDataCount() != lastRefreshCount {
                currentView.refresh_offsetY = currentView.refresh_offsetY
            }
        } else if state == .pulling {
            arrowView?.isHidden = false
            loadingView?.stopAnimating()
            UIView.animate(withDuration: NvRefreshConst.FastAnimationDuration, animations: {
                self.arrowView?.transform = .identity
            })
        } else if state == .refreshing {
            lastRefreshCount = currentView.nv_totalDataCount()
            UIView.animate(withDuration: NvRefreshConst.FastAnimationDuration, animations: {
                var bottom = self.refresh_height + self.originalInset.bottom
                let deltaH = self.heightForContentBreakView()
                if deltaH < 0 {
                    bottom -= deltaH
                }
                self.lastBottomDelta = bottom - currentView.refresh_insetB
                currentView.refresh_insetB = bottom
                currentView.refresh_offsetY = self.happenOffsetY() + self.refresh_height
            }, completion: {
                if $0 { self.executeRefreshingCallback() }
            })
            arrowView?.isHidden = true
            loadingView?.startAnimating()
        } else if state == .noMoreData {
            if lastState == .refreshing {
                UIView.animate(withDuration: NvRefreshConst.SlowAnimationDuration, animations: {
                    currentView.refresh_insetB -= self.lastBottomDelta
                    if self.isAutomaticallyChangeAlpha { self.alpha = 0 }
                }, completion: {
                    if $0 { self.pullingPercent = 0 }
                })
            }
            let deltaH = heightForContentBreakView()
            if lastState == .refreshing && deltaH > 0 && currentView.nv_totalDataCount() != lastRefreshCount {
                currentView.refresh_offsetY = currentView.refresh_offsetY
            }
            arrowView?.isHidden = true
            loadingView?.stopAnimating()
        }
    }

    private var activityIndicatorViewStyle: UIActivityIndicatorView.Style? {
        didSet {
            loadingView?.removeFromSuperview()
            loadingView = nil
            setNeedsLayout()
        }
    }

    private var stateTitles: [Int: String] = [:]
    private var lastRefreshCount: Int = 0
    private var lastBottomDelta: CGFloat = 0
}

extension NvRefreshAutoFooter {
    private func heightForContentBreakView() -> CGFloat {
        guard let currentView = scrollView else { return 0 }
        let h = currentView.refresh_height - originalInset.bottom - originalInset.top
        return currentView.contentSize.height - h
    }

    private func happenOffsetY() -> CGFloat {
        let deltaH = heightForContentBreakView()
        if deltaH > 0 {
            return deltaH - originalInset.top
        } else {
            return originalInset.top
        }
    }

    private func initCustomControl() {
        let sLabel = UILabel.refresh_label()
        let imageView = UIImageView(image: NvMaterialUIXEnvs.image(named: "arrow"))
        let loadView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
             loadView = UIActivityIndicatorView(style: .medium)
        } else {
            loadView = UIActivityIndicatorView(style: .gray)
        }
        addSubview(sLabel)
        addSubview(imageView)
        addSubview(loadView)
        stateLabel = sLabel
        arrowView = imageView
        loadingView = loadView
    }

    private func setTitle(_ title: String?, state: NvRefreshComponent.NvRefreshState) {
        guard let text = title else { return }
        stateTitles[state.rawValue] = text
    }
}
