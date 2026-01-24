//
//  NvCategoryView.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/2.
//

import UIKit

public protocol NvCategoryViewDelegate: AnyObject {
    func categoryView(_ categoryView: NvCategoryView, didSelect category: NvTabBarCategory, contentView: UIView)
    func categoryView(_ categoryView: NvCategoryView, emptyBtClicked bt: UIButton)
}

public protocol NvCategoryViewDataSource: AnyObject {
    func categoryView(_ categoryView: NvCategoryView, viewFor category: NvTabBarCategory, frame: CGRect) -> UIView
}

public class NvCategoryView: UIView, UICollectionViewDelegate {

    public weak var delegate: NvCategoryViewDelegate?
    public weak var tabDataSource: NvCategoryViewDataSource?

    public var tab: NvMaterialCategoryTab!
    private let scrollView: UIScrollView = UIScrollView()

    public var contentViews: [String: UIView] = [:]
    public var config: NvMaterialCategoryTabConfig = NvMaterialCategoryTabConfig()

    // MARK: - Init
    public init(frame: CGRect, config: NvMaterialCategoryTabConfig = NvMaterialCategoryTabConfig()) {
        self.config = config
        super.init(frame: frame)

        setupTab()
        setupScrollView()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setupTab() {
        var tabRectX = config.tabPadding.left
        var tabRectWidth = bounds.width - config.tabPadding.left - config.tabPadding.right - config.rightPadding
        
        // 左侧空按钮
        if let image = config.emptyButtonImage {
            let btn = UIButton(type: .custom)
            btn.setImage(image, for: .normal)
            btn.frame = CGRect(
                x: config.tabPadding.left,
                y: config.tabPadding.top,
                width: config.tabHeight,
                height: config.tabHeight
            )
            addSubview(btn)
            btn.addTarget(self, action: #selector(emptyBtClicked(bt:)), for: .touchUpInside)
            
            tabRectX = btn.frame.maxX - 5
            tabRectWidth = bounds.width - config.tabPadding.left - config.tabPadding.right - config.tabHeight - config.rightPadding
        }
        
        let tabFrame = CGRect(
            x: tabRectX,
            y: config.tabPadding.top,
            width: tabRectWidth,
            height: config.tabHeight
        )
        
        let tabView = NvMaterialCategoryTab(frame: tabFrame, config: config)
        addSubview(tabView)
        tabView.delegate = self
        self.tab = tabView
        
        tabView.isHidden = config.tabHidden
    }

    private func setupScrollView() {
        var tabHeight = config.tabHeight + config.tabPadding.top + config.tabPadding.bottom
        if config.tabHidden {
            tabHeight = 0
        }
        let padding = config.contentPadding
        let contentWidth = bounds.width - padding.left - padding.right
        let contentHeight = bounds.height - tabHeight - padding.top

        switch config.tabPosition {
        case .top:
            let originX = padding.left
            let originY = tabHeight + padding.top
            scrollView.frame = CGRect(
                x: originX,
                y: originY,
                width: contentWidth,
                height: contentHeight
            )
        case .bottom:
            let originX = padding.left
            let originY = padding.top
            scrollView.frame = CGRect(
                x: originX,
                y: originY,
                width: contentWidth,
                height: contentHeight
            )
            // tab 在底部，需要把 tab 移动到下面
            tab.frame.origin.y = bounds.height - config.tabHeight - config.tabPadding.bottom
        }

        scrollView.isScrollEnabled = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        addSubview(scrollView)
    }

    // MARK: - Public
    public func setCategories(categories: [NvTabBarCategory], defaultIndex: Int = 0) {
        guard !categories.isEmpty else { return }
        let validIndex = max(0, min(defaultIndex, categories.count - 1))
        self.contentViews.values.forEach { $0.removeFromSuperview() }
        tab.setCategories(categories, defaultIndex: defaultIndex)
        scrollView.contentSize = CGSize(
            width: scrollView.bounds.width * CGFloat(categories.count),
            height: scrollView.bounds.height
        )
        let selectedTab = categories[validIndex]
        checkContent(index: validIndex)
        guard let sView = contentViews[selectedTab.itemIndicate] else { return }
        delegate?.categoryView(self, didSelect: selectedTab, contentView: sView)
        
    }
    
    public var selectedIndex: Int {
        return tab.selectedTabIndex
    }

    public var selectedCategory: NvTabBarCategory? {
        return tab.selectedCategory
    }

    public var currentListView: UIView? {
        if let item = selectedCategory {
            return contentViews[item.itemIndicate]
        }
        return nil
    }

    public func selectIndex(_ index: Int, animated: Bool = true, notify: Bool = true) {
        if notify {
            tab.selectIndex(index, animated: animated, notify: notify)
        }
        checkContent(index: index)
        let offsetX = CGFloat(index) * scrollView.bounds.width
        if animated {
            scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
        } else {
            scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        }
        let categories = tab.categories
        guard index < categories.count else { return }
        let catItem = categories[index]
        guard let sView = contentViews[catItem.itemIndicate] else { return }
        delegate?.categoryView(self, didSelect: catItem, contentView: sView)
    }

    // MARK: - UIScrollViewDelegate
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        selectIndex(index, animated: true)
    }
    
    private func checkContent(index: Int) {
        let categories = tab.categories
        guard index < categories.count else { return }
        
        let catItem = categories[index]
        // 已经存在就不处理
        guard contentViews[catItem.itemIndicate] == nil else { return }
        
        // 计算 frame
        var viewFrame = scrollView.frame
        viewFrame.origin = CGPoint(x: viewFrame.width * CGFloat(index), y: 0)
        
        // 创建 view
        if let view = tabDataSource?.categoryView(self, viewFor: catItem, frame: viewFrame) {
            scrollView.addSubview(view)
            contentViews[catItem.itemIndicate] = view
        }
        
        // 控制缓存数量
        if config.maxListViewCount > 0,
            contentViews.count > config.maxListViewCount {
            // 找到距离当前 index 最远的
            if let farthestKey = contentViews.keys.max(by: { key1, key2 in
                let idx1 = categories.firstIndex { $0.itemIndicate == key1 } ?? 0
                let idx2 = categories.firstIndex { $0.itemIndicate == key2 } ?? 0
                return abs(idx1 - index) < abs(idx2 - index)
            }) {
                // 移除 view
                if let farthestView = contentViews[farthestKey] {
                    farthestView.removeFromSuperview()
                }
                contentViews.removeValue(forKey: farthestKey)
            }
        }
    }
    
    @objc func emptyBtClicked(bt: UIButton) {
        bt.isEnabled = false
        delegate?.categoryView(self, emptyBtClicked: bt)
        bt.isEnabled = true
    }
}

extension NvCategoryView: NvMaterialCategoryTabDelegate {
    public func categoryTab(_ ategoryTab: NvMaterialCategoryTab, didSelect index: Int) {
        selectIndex(index, animated: true, notify: false)
    }
}
