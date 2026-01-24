//
//  NvMaterialCategoryView.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/6/13.
//

import UIKit

public struct NvMaterialCategoryViewConfig {
    // 指定tab
    public var specifiedTabs: [NvTabBarCategory]?
    
    public var tabConfig: NvMaterialCategoryTabConfig
    public var listConfig: NvMaterialListViewConfig
    
    // 自动刷新其他tab的选中
    public var autoSelectEnabled: Bool = true
    
    public init(tabConfig: NvMaterialCategoryTabConfig = NvMaterialCategoryTabConfig(),
                listConfig: NvMaterialListViewConfig = NvMaterialListViewConfig()) {
        self.tabConfig = tabConfig
        self.listConfig = listConfig
    }
}

/// 分类视图代理
public protocol NvMaterialCategoryViewDelegate: AnyObject {
    
    /// 分类切换回调
    /// - Parameters:
    ///   - categoryView: 分类视图
    ///   - category: 新选中的分类，nil表示空项
    ///   - index: 分类索引，-1表示空项
    func categoryView(_ categoryView: NvMaterialCategoryView,
                      didSelectCategory category: NvTabBarCategory,
                      listView: NvMaterialListView)
    
    /// 素材应用回调
    /// - Parameters:
    ///   - categoryView: 分类视图
    ///   - material: 被应用的素材
    ///   - category: 所属分类
    /// - Returns: 是否应用成功
    func categoryView(_ categoryView: NvMaterialCategoryView,
                      listView: NvMaterialListView,
                      applyMaterial material: NvMaterial,
                      inCategory category: NvTabBarCategory?) -> Bool
    
    func categoryView(_ categoryView: NvMaterialCategoryView, emptyBtClicked bt: UIButton) -> Bool
    
    func categoryView(_ categoryView: NvMaterialCategoryView,
                      listView: NvMaterialListView,
                      didTouch material: NvMaterial,
                      inCategory category: NvTabBarCategory?) -> Bool
    
    func categoryView(_ categoryView: NvMaterialCategoryView, didTapAdjust material: NvMaterial)
    
    func filter(categorys: [NvTabBarCategory]) -> [NvTabBarCategory]
    
    /// 请求创建指定分类的素材列表视图
    /// - Parameters:
    ///   - categoryView: 分类视图
    ///   - category: 分类信息，nil表示空项
    ///   - frame: 推荐的frame
    /// - Returns: 素材列表视图，必须是NvMaterialListView或其子类
    func categoryView(_ categoryView: NvMaterialCategoryView,
                      createListViewFor category: NvTabBarCategory,
                      frame: CGRect) -> NvMaterialListView?
}

extension NvMaterialCategoryViewDelegate {
    
    public func categoryView(_ categoryView: NvMaterialCategoryView,
                             createListViewFor category: NvTabBarCategory,
                             frame: CGRect) -> NvMaterialListView? {
        return nil
    }
    
    public func categoryView(_ categoryView: NvMaterialCategoryView,
                             didSelectCategory category: NvTabBarCategory,
                             listView: NvMaterialListView) {}
    
    public func filter(categorys: [NvTabBarCategory]) -> [NvTabBarCategory] {
        return categorys
    }
    
    public func categoryView(_ categoryView: NvMaterialCategoryView,
                             emptyBtClicked bt: UIButton) -> Bool {
        return false
    }
    
    public func categoryView(_ categoryView: NvMaterialCategoryView,
                             listView: NvMaterialListView,
                             didTouch material: NvMaterial,
                             inCategory category: NvTabBarCategory?) -> Bool {
        return true
    }
    
    public func categoryView(_ categoryView: NvMaterialCategoryView, didTapAdjust material: NvMaterial) {}
}

// MARK: - Main View

/// 带分页展示的素材分类视图
open class NvMaterialCategoryView: UIView,
                                   NvMaterialListViewDelegate,
                                   NvCategoryViewDelegate,
                                   NvCategoryViewDataSource {
    
    public weak var delegate: NvMaterialCategoryViewDelegate?
    
    public let config: NvMaterialCategoryViewConfig
    public let listParam: NvMaterialListParam
    
    public var scrollView = UIScrollView()
    
    public var categoryView: NvCategoryView!
    
    private var stateView: NvMaterialEmptyView?
    
    /// 当前选中的素材包ID
    public var selectedPackageId: String = ""
    
    public var keyword: String?
    
    // MARK: - Init
    public init(frame: CGRect,
                listParam: NvMaterialListParam,
                config: NvMaterialCategoryViewConfig = NvMaterialCategoryViewConfig(),
                delegate: NvMaterialCategoryViewDelegate? = nil) {
        self.config = config
        self.listParam = listParam
        super.init(frame: frame)
        self.delegate = delegate
        setupCategoryView()
    }
    
    public override init(frame: CGRect) {
        self.config = NvMaterialCategoryViewConfig()
        self.listParam = NvMaterialListParam(type: .filter)
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupCategoryView() {
        var scrollViewFrame = bounds
        scrollViewFrame.size.height = scrollViewFrame.size.height - config.tabConfig.contentPadding.bottom
        scrollView.frame = scrollViewFrame
        scrollView.clipsToBounds = false
        scrollView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        
        categoryView = NvCategoryView(frame: scrollViewFrame, config: config.tabConfig)
        categoryView.delegate = self
        categoryView.tabDataSource = self
        scrollView.addSubview(categoryView)
    }
    
    open func loadCategories() {
        if let specifiedTabs = config.specifiedTabs {
            self.categoryView.setCategories(categories: specifiedTabs)
            return
        }
        guard !isLoadingCategories else { return }
        if let stateView = stateView {
            stateView.removeFromSuperview()
            self.stateView = nil
        }
        isLoadingCategories = true
        let target = NvVideoEditRequest.mallCategory(listParams: [listParam])
        NvMaterialCenter.shared().requestCategory(target: target) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingCategories = false
                switch result {
                case .success(let categories):
                    var retCategories = categories
                    if let dRet = self.delegate?.filter(categorys: retCategories) {
                        retCategories = dRet
                    }
                    if retCategories.isEmpty {
                        self.resetEmpty(state: .all, requestError: nil)
                    } else {
                        self.categoryView.setCategories(categories: retCategories)
                    }
                case .failure(let error):
                    self.resetEmpty(state: .netError, requestError: error)
                }
            }
        }
    }
    
    private var isLoadingCategories: Bool = false {
        didSet {
            categoryView.isUserInteractionEnabled = !isLoadingCategories
            if isLoadingCategories {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
        indicator.hidesWhenStopped = true
        addSubview(indicator)
        return indicator
    }()
    
    private func resetEmpty(state: NvMaterialEmptyView.StateType, requestError: NvRequestError?) {
        if let stateView = stateView {
            stateView.removeFromSuperview()
            self.stateView = nil
        }
        let nStateView = NvMaterialEmptyView(frame: self.bounds,
                                             listParam: listParam,
                                             state: state,
                                             responseError: requestError)
        addSubview(nStateView)
        
        // 让空状态视图居中显示
        nStateView.center = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
        
        nStateView.callback = { [weak self] in
            guard let self = self else { return }
            self.loadCategories()
        }
        self.stateView = nStateView
    }
    
    // MARK: - Public
    public func selectCategory(at index: Int) {
        categoryView.selectIndex(index)
    }
    
    public var selectedIndex: Int {
        return categoryView.selectedIndex
    }
    
    public var selectedCategory: NvTabBarCategory? {
        return categoryView.selectedCategory
    }
    
    public var currentListView: NvMaterialListView? {
        return categoryView.currentListView as? NvMaterialListView
    }
    
    public var materialListViews: [NvMaterialListView] {
        var array = [NvMaterialListView]()
        for item in categoryView.contentViews.values {
            if let mListView = item as? NvMaterialListView {
                array.append(mListView)
            }
        }
        return array
    }
    
    /// 更新搜索条件
    open func updateSearchKey(keyword: String?) {
        self.keyword = keyword
        for item in categoryView.contentViews.values {
            if let mListView = item as? NvMaterialListView {
                mListView.updateSearchKey(keyword: keyword)
            }
        }
    }
    
    /// 更新选中状态
    /// - Parameter packageId: 要选中的素材包ID，传空字符串表示取消所有选中
    public func updateSelectedPackageId(_ packageId: String) {
        guard selectedPackageId != packageId, config.autoSelectEnabled else { return }
        selectedPackageId = packageId
        for item in categoryView.contentViews.values {
            if let mListView = item as? NvMaterialListView {
                mListView.updateSelectedPackageId(packageId)
            }
        }
    }
    
    // MARK: - NvMaterialListViewDelegate
    open func listView(_ listView: NvMaterialListView, downloadItemAt indexPath: IndexPath, material: NvMaterial) -> Bool {
        guard listView === currentListView else { return true }
        let category = selectedCategory
        let applied = delegate?.categoryView(self,
                                             listView: listView,
                                             applyMaterial: material,
                                             inCategory: category) ?? false
        if applied {
            updateSelectedPackageId(listView.itemSelectIndicate(item: material))
        }
        return applied
    }
    
    public func categoryView(_ categoryView: NvCategoryView, emptyBtClicked bt: UIButton) {
        let applied = delegate?.categoryView(self, emptyBtClicked: bt) ?? false
        if applied {
            updateSelectedPackageId("")
        }
    }
    
    open func listView(_ listView: NvMaterialListView, didTouchItemAt indexPath: IndexPath, material: NvMaterial) -> Bool {
        // 素材被点击时的处理, 返回是否需要应用
        guard listView === currentListView else { return true }
        let category = selectedCategory
        let applied = delegate?.categoryView(self,
                                             listView: listView,
                                             didTouch: material,
                                             inCategory: category) ?? true
        return applied
    }
    
    public func listView(_ listView: NvMaterialListView, didTapAdjust material: NvMaterial) {
        delegate?.categoryView(self, didTapAdjust: material)
    }
    
    // MARK: - NvCategoryViewDelegate
    open func categoryView(_ categoryView: NvCategoryView, didSelect category: any NvTabBarCategory, contentView: UIView) {
        guard let listView = contentView as? NvMaterialListView else { return }
        listView.startLoadData()
        delegate?.categoryView(self, didSelectCategory: category, listView: listView)
        for item in categoryView.contentViews.values {
            if let mListView = item as? NvMaterialListView {
                mListView.cleanPendingApplyAction()
            }
        }
    }
    
    // MARK: - NvCategoryViewDataSource
    open func categoryView(_ categoryView: NvCategoryView, viewFor category: NvTabBarCategory, frame: CGRect) -> UIView {
        var listFrame = frame
        if config.tabConfig.listHeight > 0 {
            listFrame.size.height = config.tabConfig.listHeight
        }
        if let listView = delegate?.categoryView(self, createListViewFor: category, frame: listFrame) {
            listView.applyDelegate = self
            listView.keyword = keyword
            listView.updateSelectedPackageId(selectedPackageId)
            return listView
        } else {
            let flowLayout = NvMaterialListViewLayout.listViewFlowLayout(frame: listFrame, listParam: listParam)
            let listView = NvMaterialListView(frame: listFrame,
                                              collectionViewLayout: flowLayout,
                                              config: config.listConfig,
                                              listParam: category.listParam)
            listView.keyword = keyword
            listView.applyDelegate = self
            listView.updateSelectedPackageId(selectedPackageId)
            return listView
        }
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
