//
//  NvMaterialCategoryTab.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/2.
//

import UIKit

// MARK: - Configuration
/// 分类Tab配置
public struct NvMaterialCategoryTabConfig {
    
    public var tabHidden: Bool = false
    
    public enum TabPosition {
        case top
        case bottom
    }
    public enum UnderlineStyle {
        case line          // 下划线
        case pill   // 圆角矩形
        case none          // 无下划线
    }
    
    // 下划线样式
    public var underlineStyle: UnderlineStyle = .line

    public var tabPosition: TabPosition = .top
    public var tabPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 8, right: 10)
    public var contentPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    public var listHeight: CGFloat = -1 // > 0 有效
    
    public var tabItemPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: -6)
    /// Tab高度
    public var tabHeight: CGFloat = 44 * NvMaterialUIXEnvs.scale
    /// Tab背景颜色
    public var tabBackgroundColor: UIColor = .clear
    
    /// 字体
    public var font: UIFont = UIFont.systemFont(ofSize: 14 * NvMaterialUIXEnvs.scale)
    
    /// 选中文字颜色
    public var selectedTextColor: UIColor = UIColor.white
    /// 未选中文字颜色
    public var normalTextColor: UIColor = UIColor.gray
    
    /// 下划线高度
    public var underlineHeight: CGFloat = 2
    
    public var underlineWidth: CGFloat = 15 * NvMaterialUIXEnvs.scale
    /// 下划线高度
    public var underlineOffset: CGFloat = -5
    /// 下划线颜色
    public var underlineColor: UIColor = UIColor.white
    /// 下划线圆角
    public var underlineCornerRadius: CGFloat = 1
    
    
    // pill（圆角矩形）相关
    /// pill 的高度（当 underlineStyle == .pill）
    public var pillHeight: CGFloat = 20 * NvMaterialUIXEnvs.scale
    /// pill 相对于 cell 宽度的左右内边距（pillWidth = cell.width - pillHorizontalPadding * 2）
    public var pillHorizontalPadding: CGFloat = 0
    /// pill 圆角（如果为 0，会自动使用 pillHeight / 2）
    public var pillCornerRadius: CGFloat = 0
    
    /// 空项按钮标题
    public var emptyButtonImage: UIImage?
    /// 右侧留白宽度（用于放置完成按钮等）
    public var rightPadding: CGFloat = 5
    /// Tab切换动画时长
    public var animationDuration: TimeInterval = 0.25
    
    public var maxListViewCount: Int = 5
    
    public init() {}
}

// MARK: - Tab Item Cell
class NvTabItemCell: UICollectionViewCell {
    let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.layer.masksToBounds = true   // ✅ 圆角生效
        contentView.backgroundColor = .clear     // ✅ 默认透明
        
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func applyConfig(_ config: NvMaterialCategoryTabConfig, selected: Bool) {
    }
}

public protocol NvMaterialCategoryTabDelegate: AnyObject {
    func categoryTab(_ ategoryTab: NvMaterialCategoryTab, didSelect index: Int)
}

// MARK: - Tab View
public class NvMaterialCategoryTab: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public var config = NvMaterialCategoryTabConfig()
    
    public weak var delegate: NvMaterialCategoryTabDelegate?
    
    public var categories: [NvTabBarCategory] = []
    private var selectedIndex: Int = 0
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = config.tabBackgroundColor
        cv.register(NvTabItemCell.self, forCellWithReuseIdentifier: "cell")
        return cv
    }()
    
    private let underlineView = UIView()
    
    // MARK: - Init
    public init(frame: CGRect, config: NvMaterialCategoryTabConfig) {
        super.init(frame: frame)
        self.config = config
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        underlineView.backgroundColor = config.underlineColor
        underlineView.layer.masksToBounds = true
        underlineView.isHidden = true
        collectionView.addSubview(underlineView)
        underlineView.layer.zPosition = -1
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Public
    public func setCategories(_ categories: [NvTabBarCategory], defaultIndex: Int = 0) {
        self.categories = categories
        let validIndex = max(0, min(defaultIndex, categories.count - 1))
        selectedIndex = validIndex
        collectionView.reloadData()
        layoutIfNeeded()
        updateUnderline(to: selectedIndex, animated: false)
    }
    
    public var selectedTabIndex: Int {
        return selectedIndex
    }

    public var selectedCategory: NvTabBarCategory? {
        if selectedIndex < categories.count {
            return categories[selectedIndex]
        }
        return nil
    }
    
    public func selectIndex(_ index: Int, animated: Bool = true, notify: Bool = true) {
        guard index >= 0 && index < categories.count else { return }
        guard selectedIndex != index && index < categories.count else { return }
        selectedIndex = index
        updateUnderline(to: index, animated: animated)
        collectionView.reloadData()
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
        if notify {
            delegate?.categoryTab(self, didSelect: index)
        }
    }
    
    // MARK: - Underline
    // MARK: - Underline
    private func updateUnderline(to index: Int, animated: Bool) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else { return }
        let cellFrame = cell.frame
        let cellWidth = cellFrame.width
        let cellX = cellFrame.origin.x

        var targetFrame = CGRect.zero

        switch config.underlineStyle {
        case .line:
            let width = config.underlineWidth
            let x = cellX + (cellWidth - width) * 0.5
            let y = collectionView.frame.height - config.underlineHeight + config.underlineOffset
            targetFrame = CGRect(x: x, y: y, width: width, height: config.underlineHeight)
            underlineView.layer.cornerRadius = config.underlineCornerRadius
            underlineView.isHidden = false

        case .pill:
            let horizontalPadding = config.pillHorizontalPadding
            let width = max(0, cellWidth - horizontalPadding * 2)
            let height = config.pillHeight
            let x = cellX + (cellWidth - width) * 0.5
            let y = (collectionView.frame.height - height) * 0.5 + config.underlineOffset
            targetFrame = CGRect(x: x, y: y, width: width, height: height)
            underlineView.layer.cornerRadius = (config.pillCornerRadius > 0) ? config.pillCornerRadius : (height * 0.5)
            underlineView.isHidden = false

        case .none:
            underlineView.isHidden = true
            return
        }

        let applyFrame = {
            self.underlineView.frame = targetFrame
            self.collectionView.bringSubviewToFront(self.underlineView)
        }

        if animated {
            UIView.animate(withDuration: config.animationDuration, animations: applyFrame)
        } else {
            applyFrame()
        }
    }
    
    // MARK: - CollectionView DataSource / Delegate
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! NvTabItemCell
        let item = categories[indexPath.item]
        let selected = indexPath.item == selectedIndex
        
        cell.titleLabel.text = item.displayName
        cell.titleLabel.font = config.font
        cell.titleLabel.textColor = selected ? config.selectedTextColor : config.normalTextColor
        cell.applyConfig(config, selected: selected)   // ✅ 设置圆角边框
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectIndex(indexPath.item)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = categories[indexPath.item]
        let size = (item.displayName as NSString).size(withAttributes: [.font: config.font])
        return CGSize(width: size.width - config.tabItemPadding.left - config.tabItemPadding.right,
                      height: config.tabHeight)
    }
}
