import UIKit

public extension NvRefreshComponent {
    enum NvRefreshState: Int {
        case idel = 0
        case pulling
        case refreshing
        case willRefresh
        case noMoreData
    }
}

open class NvRefreshComponent: UIView {
    public private(set) weak var scrollView: UIScrollView?
    /// 记录scrollView刚开始的inset / Records the beginning inset of the scrollView
    public var originalInset: UIEdgeInsets = .zero
    /// 拉拽的百分比(交给子类重写) / Percentage of drag (let subclass override)
    public var pullingPercent: CGFloat = 0 {
        didSet {
            guard !isRefreshing else { return }
            alpha = isAutomaticallyChangeAlpha ? pullingPercent : 1
        }
    }

    /// 根据拖拽比例自动切换透明度 / Automatically toggles transparency according to drag ratio
    public var isAutomaticallyChangeAlpha: Bool = true {
        didSet {
            guard !isRefreshing else { return }
            alpha = isAutomaticallyChangeAlpha ? pullingPercent : 1
        }
    }

    public var isRefreshing: Bool {
        state == .refreshing || state == .willRefresh
    }

    public var state: NvRefreshState = .idel {
        didSet {
            if state == oldValue { return }
            updateRefreshState(for: oldValue)
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
        state = .idel
    }

    public func configRefreshEvent(target: AnyObject, action: Selector) {
        refreshingTarget = target
        refreshingAction = action
    }

    public func executeRefreshingCallback() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let target = self.refreshingTarget, let action = self.refreshingAction else { return }
            if target.responds(to: action) {
                _ = target.perform(action)
            }
        }
    }

    open func prepare() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = UIColor.clear
    }

    open func updateRefreshState(for _: NvRefreshState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setNeedsLayout()
        }
    }

    open func beginRefreshing() {
        UIView.animate(withDuration: NvRefreshConst.FastAnimationDuration, animations: {
            self.alpha = 1.0
        })
        pullingPercent = 1.0
        if window != nil {
            state = .refreshing
        } else {
            if state != .refreshing {
                state = .willRefresh
                setNeedsLayout()
            }
        }
    }

    open func endRefreshing() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.state = .idel
        }
    }

    // 子类实现 / Subclass implementation
    open func configScrollViewBounce(_: UIView?) {}
    open func placeSubviews() {}
    open func scrollViewContentOffsetDidChanged(change _: [NSKeyValueChangeKey: Any]?) {}
    open func scrollViewContentSizeDidChanged(change _: [NSKeyValueChangeKey: Any]?) {}
    open func scrollViewPanStateDidChanged(change _: [NSKeyValueChangeKey: Any]?) {}

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var pan: UIPanGestureRecognizer?
    private var refreshingAction: Selector?
    private weak var refreshingTarget: AnyObject?
    
    private var contentSizeKvoToken: NSKeyValueObservation?
    private var offsetKvoToken: NSKeyValueObservation?
}

extension NvRefreshComponent {
    override open func layoutSubviews() {
        placeSubviews()
        super.layoutSubviews()
    }

    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        // 如果不是UIScrollView，不做任何事情 / If it's not UIScrollView, don't do anything
        guard let superScrollView = newSuperview as? UIScrollView  else { return }
        // 旧的父控件移除监听 / The old parent control removes the listener
        removeObservers()
        scrollView = superScrollView
        // 设置宽度 / Width
        refresh_width = superScrollView.refresh_width - superScrollView.refresh_insetL - superScrollView.refresh_insetR
        // 设置位置 / X
        refresh_x = 0
        // 记录UIScrollView最开始的contentInset
        // Records the contentInset at the beginning of the UIScrollView
        originalInset = superScrollView.refresh_inset
        // 添加监听
        addObservers()
        // 设置弹簧效果 / Set spring effect
        configScrollViewBounce(newSuperview)
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        if state == .willRefresh {
            state = .refreshing
        }
    }
}

extension NvRefreshComponent {
    private func addObservers() {
        let _: NSKeyValueObservingOptions = [.new, .old]
        offsetKvoToken = scrollView?.observe(\UIScrollView.contentOffset, options: .new) { [weak self] (_, change) in
            guard let self = self else { return }
            if self.isHidden { return }
            if change.newValue != nil {
                self.scrollViewContentOffsetDidChanged(change: nil)
            }
        }
        contentSizeKvoToken = scrollView?.observe(\UIScrollView.contentSize, options: .new) { [weak self] (_, change) in
            guard let self = self else { return }
            if change.newValue != nil {
                self.scrollViewContentSizeDidChanged(change: nil)
            }
        }
    }

    private func removeObservers() {
        pan = nil
        
        offsetKvoToken?.invalidate()
        contentSizeKvoToken?.invalidate()
    }
}
