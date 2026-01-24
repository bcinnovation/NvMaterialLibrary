//
//  NvMaterialListView.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/6/13.
//

import UIKit

/// 素材列表视图配置
public struct NvMaterialListViewConfig {
    public var hideCellTitle: Bool
    public var contentInset = UIEdgeInsets(top: 0,
                                           left: 15 * NvMaterialUIXEnvs.scale,
                                           bottom: 0,
                                           right: 15 * NvMaterialUIXEnvs.scale)
    public var needsEmptyItem: Bool
    public var selectable: Bool = true
    public var isAutoScrollSelectedItem: Bool = false
    public var adjustmentEnabled: Bool = true
    
    public init(hideCellTitle: Bool = true, needsEmptyItem: Bool = false) {
        self.hideCellTitle = hideCellTitle
        self.needsEmptyItem = needsEmptyItem
    }
}

/// 素材列表视图代理协议
public protocol NvMaterialListViewDelegate: AnyObject {
    /// 素材下载完成并被点击时的回调
    /// - Parameters:
    ///   - listView: 素材列表视图
    ///   - indexPath: 被点击素材的索引路径
    ///   - material: 被点击的素材对象
    /// - Returns: 是否应用成功需要切换选中
    func listView(_ listView: NvMaterialListView, downloadItemAt indexPath: IndexPath, material: NvMaterial) -> Bool
    
    /// 素材被点击时的回调（无论下载状态）
    /// - Parameters:
    ///   - listView: 素材列表视图
    ///   - indexPath: 被点击素材的索引路径  
    ///   - material: 被点击的素材对象
    ///   - Returns: 是否需要应用
    func listView(_ listView: NvMaterialListView, didTouchItemAt indexPath: IndexPath, material: NvMaterial) -> Bool
    
    /// 素材调参按钮点击时的回调
    /// - Parameters:
    ///   - listView: 素材列表视图
    ///   - material: 被点击调参的素材对象
    func listView(_ listView: NvMaterialListView, didTapAdjust material: NvMaterial)
    
}

extension NvMaterialListViewDelegate {
    public func listView(_ listView: NvMaterialLibrary.NvMaterialListView,
                         didTouchItemAt indexPath: IndexPath,
                         material: NvMaterialLibrary.NvMaterial) -> Bool {
        return true
    }
    
    public func listView(_ listView: NvMaterialListView, didTapAdjust material: NvMaterial) {}
}

/// 素材列表视图
/// 
/// 用于显示和管理素材的集合视图，支持:
/// - 分页加载素材数据
/// - 自动下载状态管理
/// - 下拉刷新和上拉加载更多
/// - 空状态和错误状态显示
/// - 水平和垂直滚动布局
/// 
/// **使用示例:**
/// ```swift
/// let layout = UICollectionViewFlowLayout()
/// let config = NvMaterialListViewConfig(hideCellTitle: false)
/// let param = NvMaterialListParam(type: .filter)
/// let listView = NvMaterialListView(frame: frame, 
///                                   collectionViewLayout: layout,
///                                   config: config, 
///                                   listParam: param)
/// listView.applyDelegate = self
/// listView.startLoadData()
/// ```
open class NvMaterialListView: UIView {
    
    public var listParam: NvMaterialListParam
    public var filterListParam: NvMaterialListParam?
    
    public var pageSize: Int = 20
    private var pageNum: Int = 0
    
    public var responseDataCount: Int = 0
    public var dataArray = [NvMaterial]()
    
    public var keyword: String?
    
    private var isHorizontalScroll: Bool = false
    public  var hasLoaded: Bool = false
    private var isRefreshing: Bool = false
    private var isLoadingMore: Bool = false
    
    /// 当前选中的素材包ID
    public var selectedPackageId: String = ""
    
    /// 待应用的素材包ID（最后一次点击的未下载素材）
    private var pendingApplyPackageId: String = ""
    
    public var config: NvMaterialListViewConfig
    
    public var stateView: NvMaterialEmptyView?
    
    public weak var applyDelegate: NvMaterialListViewDelegate?
    
    private var listView: UICollectionView?
    
    private var cellType: NvMaterialCell.Type = NvMaterialCell.self
    
    public init(frame: CGRect,
                collectionViewLayout layout: UICollectionViewLayout,
                config: NvMaterialListViewConfig,
                listParam: NvMaterialListParam,
                cellType: NvMaterialCell.Type = NvMaterialCell.self) {
        self.config = config
        self.listParam = listParam
        super.init(frame: frame)
        backgroundColor = .clear
        self.cellType = cellType
        self.isHorizontalScroll = false
        if let layout = layout as? UICollectionViewFlowLayout {
            self.isHorizontalScroll = layout.scrollDirection == .horizontal
        }
        setupCollectionView(layout: layout)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 开始加载数据并设置刷新控件
    ///
    /// 根据滚动方向自动配置相应的刷新控件：
    /// - 水平滚动：添加右侧加载更多控件
    /// - 垂直滚动：添加下拉刷新和上拉加载更多控件
    ///
    /// - Note: 请在将视图添加到父视图后调用此方法
    open func startLoadData() {
        if let stateView = stateView {
            stateView.removeFromSuperview()
            self.stateView = nil
        }
        guard let listView = listView else { return }
        if isHorizontalScroll { // 水平滑动
            if listView.nv_trailer == nil {
                listView.nv_trailer = NvRefreshAutoTrailer.trailer(forTarget: self, action: #selector(nv_loadMoreData))
            }
            if !hasLoaded {
                nv_loadNewData()
            } else {
                reloadList()
            }
        } else { // 纵向滑动
            if listView.nv_footer == nil {
                listView.nv_footer = NvRefreshAutoFooter.footer(forTarget: self,
                                                                action: #selector(nv_loadMoreData))
                listView.nv_footer?.isHidden = true
            }
            if let header = listView.nv_header {
                if header.state == .refreshing {
                    header.state = .idel
                    header.state = .refreshing
                    return
                }
            } else {
                listView.nv_header = NvDotRefreshHeader.header(forTarget: self,
                                                                action: #selector(nv_loadNewData))
            }
            if !hasLoaded && !isRefreshing {
                listView.nv_header?.beginRefreshing()
            } else {
                reloadList()
            }
        }
    }
    
    open func itemSelectedState(item: NvMaterial, selectedIndicate: String?) -> Bool {
        if selectedIndicate == nil && item.packageId.isEmpty {
            return true
        }
        return item.packageId == selectedIndicate
    }
    
    open func itemSelectIndicate(item: NvMaterial) -> String {
        return item.packageId
    }
    
    open func materialTargetType(listParam: NvMaterialListParam,
                                 page: Int,
                                 pageSize: Int = 20,
                                 ratio: Int = 0,
                                 keyword: String? = nil) -> NvMaterialTargetType {
        let target = NvVideoEditRequest.mall(listParam: listParam,
                                             page: page,
                                             pageSize: pageSize,
                                             ratio: ratio,
                                             keyword: keyword)
        return target
    }
    
    // 将要切换到其他tab时，需要清理选中动作，素材包下载完成后就不再继续应用
    // When you are about to switch to another tab, you need to clear the selected action. Once the material package is downloaded, it will no longer be applied
    open func cleanPendingApplyAction() {
        pendingApplyPackageId = ""
    }
    
    open func resetEmpty(state: NvMaterialEmptyView.StateType, responseError: NvRequestError?) {
        if let stateView = stateView {
            stateView.removeFromSuperview()
            self.stateView = nil
        }
        if dataArray.isEmpty {
            let nStateView = NvMaterialEmptyView(frame: self.bounds,
                                                 listParam: listParam,
                                                 state: state,
                                                 responseError: responseError)
            addSubview(nStateView)
            
//            nStateView.center = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
            
            nStateView.callback = { [weak self] in
                guard let self = self else { return }
                if !self.isRefreshing {
                    self.nv_loadNewData()
                }
            }
            self.stateView = nStateView
        }
    }
    
    open func reloadList() {
        listView?.reloadData()
    }
    
    /// 更新搜索条件
    open func updateSearchKey(keyword: String?) {
        self.hasLoaded = false
        self.keyword = keyword
        pendingApplyPackageId = ""
        nv_loadNewData()
    }
    
    /// 更新选中状态
    /// - Parameter packageId: 要选中的素材包ID，传空字符串表示取消所有选中
    open func updateSelectedPackageId(_ packageId: String) {
        guard config.selectable else { return }
        let oldSelectedId = selectedPackageId
        selectedPackageId = packageId
        
        let indexPaths = indexPathsToReload(oldId: oldSelectedId, newId: packageId)
        
        guard !indexPaths.isEmpty else { return }
        
        DispatchQueue.main.async {
            // 检查 indexPath 是否仍然有效
            let validIndexPaths = indexPaths.filter { $0.item < self.dataArray.count }
            if !validIndexPaths.isEmpty {
                self.listView?.reloadItems(at: validIndexPaths)
            }
        }
    }
    open func scrollToSelectedItem() {
        guard !selectedPackageId.isEmpty else { return }
        for (i, item) in dataArray.enumerated() {
            let newSelectState = itemSelectedState(item: item, selectedIndicate: selectedPackageId)
            if newSelectState {
                scrollToItem(index: i)
                break
            }
        }
    }
    
    fileprivate func scrollToItem(index: Int, animated: Bool = true) {
        if dataArray.count > index {
            listView?.scrollToItem(at: IndexPath(item: index, section: 0),
                              at: isHorizontalScroll ? .centeredHorizontally : .centeredVertically,
                              animated: animated)
        }
    }
    
    open func setupCollectionView(layout: UICollectionViewLayout) {
        let cRect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        let collectionView = UICollectionView(frame: cRect, collectionViewLayout: layout)
        addSubview(collectionView)
        collectionView.nvRegister(cellType: cellType)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        
        collectionView.contentInset = config.contentInset
        
        let materialCenter = NvMaterialCenter.shared()
        materialCenter.add(observer: self)
        listView = collectionView
    }
}

extension NvMaterialListView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.nvDequeueReusableCell(for: indexPath, cellType: cellType)
        let model = dataArray[indexPath.item]
        cell.nv_renderCell(for: model, hidden: config.hideCellTitle, adjustmentEnabled: config.adjustmentEnabled)
        
        // 设置选中状态
        let isSelected = config.selectable ? itemSelectedState(item: model, selectedIndicate: selectedPackageId) : false
        cell.nv_setSelected(isSelected)
        
        return cell
    }
    
}

extension NvMaterialListView {
    
    private func filterResponseData(items: [NvMaterial]) -> [NvMaterial] {
        guard let filterListParam = filterListParam else {
            return items
        }
        
        return items.filter { material in
            // 必须匹配 type
            guard material.type == filterListParam.type else {
                return false
            }
            
            // categoryId 如果有值，则要匹配
            if let categoryId = filterListParam.categoryId,
               material.category != categoryId {
                return false
            }
            
            // kindId 如果有值，则要匹配
            if let kindId = filterListParam.kindId,
               material.kind != kindId {
                return false
            }
            
            return true
        }
    }
    
    @objc private func nv_loadNewData() {
        guard let listView = listView else { return }
        guard !isRefreshing else {
            log.warn("Already refreshing, ignoring duplicate refresh request")
            return
        }
        cleanPendingApplyAction()
        isRefreshing = true
        refresh { [weak self] result in
            guard let self = self else { return }
            self.isRefreshing = false
            listView.nv_header?.endRefreshing()
            switch result {
            case .success(let hasMore):
                self.hasLoaded = true
                self.reloadList()
                endFooterRefresh(hasMore: dataArray.isEmpty ? false : hasMore)
                resetEmpty(state: .all, responseError: nil)
                if !self.selectedPackageId.isEmpty,
                    self.config.isAutoScrollSelectedItem {
                    self.scrollToSelectedItem()
                }
            case .failure(let error):
                resetEmpty(state: .netError, responseError: error)
                hideFooterRefresh()
            }
        }
    }
    
    public func resetDataSource(items: [NvMaterial]) {
        cleanPendingApplyAction()
        dataArray.removeAll()
        dataArray.append(contentsOf: items)
        reloadList()
    }

    @objc private func nv_loadMoreData() {
        guard !isLoadingMore else {
            log.warn("Already loading more, ignoring duplicate load more request")
            return
        }
        
        isLoadingMore = true
        loadMore() { [weak self] result in
            guard let self = self else { return }
            self.isLoadingMore = false
            switch result {
            case .success(let responseData):
                guard !responseData.newItems.isEmpty else {
                    endFooterRefresh(hasMore: false)
                    return
                }
                self.listView?.performBatchUpdates {
                    self.listView?.insertItems(at: responseData.newItems)
                }
                endFooterRefresh(hasMore: responseData.hasMore)
            case .failure(let error):
                log.error("Load more failed: \(error)")
                endFooterRefresh(hasMore: true)
            }
        }
    }
    
    private func endFooterRefresh(hasMore: Bool) {
        guard let listView = listView else { return }
        if isHorizontalScroll {
            if !hasMore {
                listView.nv_trailer?.endRefreshingWithNoMoreData()
            } else {
                listView.nv_trailer?.endRefreshing()
            }
            listView.nv_trailer?.isHidden = dataArray.isEmpty
        } else {
            listView.nv_header?.endRefreshing()
            if !hasMore {
                listView.nv_footer?.isHidden = dataArray.isEmpty
                listView.nv_footer?.endRefreshingWithNoMoreData()
            } else {
                listView.nv_footer?.isHidden = false
                listView.nv_footer?.endRefreshing()
            }
        }
    }
    private func hideFooterRefresh() {
        guard let listView = listView else { return }
        listView.nv_trailer?.isHidden = true
        listView.nv_footer?.isHidden = true
    }
}

extension NvMaterialListView: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = dataArray[indexPath.item]
        
        if applyDelegate?.listView(self, didTouchItemAt: indexPath, material: model) == false {
            log.trace("didTouchItemAt ret: false, Block the application")
            return
        }
        
        // 空项素材直接回调应用
        if model.packageId.isEmpty {
            pendingApplyPackageId = model.packageId // 空字符串
            if applyDelegate?.listView(self, downloadItemAt: indexPath, material: model) == true {
                updateSelectedPackageId(model.packageId)
            }
            return
        }
        
        let state = model.downloadStatus
        if state == .none {
            // 记录待应用的素材ID（最后一次点击的）
            pendingApplyPackageId = model.packageId
            
            let materialCenter = NvMaterialCenter.shared()
            if materialCenter.download(material: model) {
                DispatchQueue.main.async {
//                    collectionView.reloadItems(at: [indexPath])
                    if let cell = collectionView.cellForItem(at: indexPath) as? NvMaterialCell {
                        cell.setDownload(state: .downloading)
                    }
                }
            } else {
                // 下载启动失败，清除待应用状态
                pendingApplyPackageId = ""
                log.warn("Failed to start download for material: \(model.packageId)")
            }
        } else if state == .downloading {
            // 如果正在下载，也更新待应用ID（支持在下载过程中切换目标）
            pendingApplyPackageId = model.packageId
        } else if state == .finished {
            if model.packageId == selectedPackageId {
                if config.adjustmentEnabled {
                    applyDelegate?.listView(self, didTapAdjust: model)
                } else {
                    log.info("The same effect package was selected")
                }
                return
            }
            // 立即应用已下载的素材
            pendingApplyPackageId = model.packageId
            if applyDelegate?.listView(self, downloadItemAt: indexPath, material: model) == true {
                updateSelectedPackageId(model.packageId)
                pendingApplyPackageId = ""
            }
            
        }
    }
    
}

extension NvMaterialListView: NvMaterialDownloadStateDelegate {
    
    public func materialCenter(packageId: String,
                               type: NvMaterialType,
                               categorie: Int,
                               kind: Int,
                               download progress: Double) {
        guard type == listParam.type else { return }
        if let categoryId = listParam.categoryId, categoryId > 0 {
            guard categoryId == categorie else { return }
        }
        if let kindId = listParam.kindId, kindId > 0 {
            guard kindId == kind else { return }
        }
        log.trace("\(packageId) download progress:\(progress)")
    }
    
    public func materialCenterDownloadCompleted(packageId: String,
                                                type: NvMaterialType,
                                                categorie: Int,
                                                kind: Int,
                                                result: Result<(packagePath: String, licPath: String), NvRequestError>) {
        guard type == listParam.type else { return }
        if let categoryId = listParam.categoryId, categoryId > 0 {
            guard categoryId == categorie else { return }
        }
        if let kindId = listParam.kindId, kindId > 0 {
            guard kindId == kind else { return }
        }
        
        DispatchQueue.main.async {
            var downloadedMaterial: NvMaterial?
            
            var changedIndexPaths: [IndexPath] = []
            
            for i in 0..<self.dataArray.count {
                let model = self.dataArray[i]
                if model.packageId == packageId {
                    changedIndexPaths.append(IndexPath(item: i, section: 0))
                    downloadedMaterial = model
                    switch result {
                    case .success(let info):
                        model.downloadStatus = .finished
                        model.packagePath = info.packagePath
                        model.licPath = info.licPath
                    case .failure(let error):
                        model.downloadStatus = .none
                        if model.packageId == self.pendingApplyPackageId {
                            self.cleanPendingApplyAction()
                        }
                        log.error("materialCenter download error:\(error)")
                    }
                    break
                }
            }
            // 检查是否需要自动应用（只应用最后一次点击的素材）
            if case .success = result,
               packageId == self.pendingApplyPackageId,
               let material = downloadedMaterial,
               let indexPath = changedIndexPaths.first {
                
                // 清除待应用状态，防止重复应用
                self.pendingApplyPackageId = ""
                
                // 自动应用下载完成的素材，根据返回值决定是否需要刷新
                let applyRet = self.applyDelegate?.listView(self, downloadItemAt: indexPath, material: material) ?? true
                
                // 如果应用成功，切换选中
                if applyRet {
                    let oldSelectedId = self.selectedPackageId
                    self.selectedPackageId = packageId
                    let indexPaths = self.indexPathsToReload(oldId: oldSelectedId, newId: packageId)
                    if !indexPaths.isEmpty {
                        changedIndexPaths.append(contentsOf: indexPaths)
                    }
                }
            }
            // 刷新对应的cell
            if !changedIndexPaths.isEmpty {
                self.listView?.reloadItems(at: changedIndexPaths)
            }
        }
    }
    
}

// MARK: -- request
extension NvMaterialListView {
    
    private func refresh(completion:@escaping (Result<Bool, NvRequestError>) -> Void) {
        let target = materialTargetType(listParam: listParam, page: 1, pageSize: pageSize, keyword: keyword)
        NvMaterialCenter.shared().requestMaterial(target: target) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let responseData):
                    self.pageNum = 1
                    self.responseDataCount = responseData.items.count
                    self.dataArray = self.filterResponseData(items: responseData.items)
                    
                    // 如果需要空项且列表不为空，在开头插入空项
                    if self.config.needsEmptyItem && !self.dataArray.isEmpty {
                        let emptyMaterial = self.createEmptyMaterial()
                        self.dataArray.insert(emptyMaterial, at: 0)
                    }
                    
                    var hasMore = responseData.hasMore
                    if responseData.total >= 0 {
                        hasMore = responseData.total > self.responseDataCount
                    }
                    completion(.success(hasMore))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func loadMore(completion:@escaping (Result<(newItems: [IndexPath], hasMore: Bool),
                                                NvRequestError>) -> Void) {
        let nPageNum = pageNum + 1
        let target = materialTargetType(listParam: listParam, page: nPageNum, pageSize: pageSize, keyword: keyword)
        NvMaterialCenter.shared().requestMaterial(target: target) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let responseData):
                    let nItems = self.filterResponseData(items: responseData.items)
                    var nIndexPaths = [IndexPath]()
                    let originCount = self.dataArray.count
                    if !nItems.isEmpty {
                        for i in 0..<nItems.count {
                            nIndexPaths.append(IndexPath(item: i + originCount, section: 0))
                        }
                    }
                    self.responseDataCount += responseData.items.count
                    self.pageNum = nPageNum
                    self.dataArray.append(contentsOf: nItems)
                    var hasMore = responseData.hasMore
                    if responseData.total >= 0 {
                        hasMore = responseData.total > self.responseDataCount
                    }
                    completion(.success((newItems: nIndexPaths, hasMore: hasMore)))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 创建空项素材
    public func createEmptyMaterial() -> NvMaterial {
        let emptyMaterial = NvMaterial()
        emptyMaterial.type = listParam.type
        emptyMaterial.category = listParam.categoryId ?? 0
        emptyMaterial.kind = listParam.kindId ?? 0
        emptyMaterial.packageId = ""
        emptyMaterial.displayName = NvMaterialUIXEnvs.localizedString(key: "material_none", comment: "空项素材标题")
        emptyMaterial.coverUrl = "material_none" // 特殊标识，UI层需要识别并显示对应图片
        emptyMaterial.zipUrl = ""
        emptyMaterial.version = ""
        emptyMaterial.packagePath = ""
        emptyMaterial.licPath = ""
        emptyMaterial.downloadStatus = .finished
        return emptyMaterial
    }
    
    /// 找到需要刷新的 cell 索引
    /// Find the index paths of cells that need to be reloaded
    ///
    /// - Parameters:
    ///   - oldId: 之前选中的 packageId / The previously selected packageId
    ///   - newId: 当前要选中的 packageId / The newly selected packageId
    /// - Returns: 需要刷新的 IndexPath 数组 / An array of IndexPaths to be reloaded
    private func indexPathsToReload(oldId: String, newId: String) -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        for (index, material) in dataArray.enumerated() {
            let materialPackageId = itemSelectIndicate(item: material)
            if materialPackageId == oldId || materialPackageId == newId {
                indexPaths.append(IndexPath(item: index, section: 0))
            }
        }
        return indexPaths
    }

}
