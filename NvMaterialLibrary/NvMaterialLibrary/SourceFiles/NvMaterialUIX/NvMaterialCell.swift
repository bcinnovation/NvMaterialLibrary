//
//  NvMaterialCell.swift
//  MYVideo
//
//  Created by chengww on 2021/3/15.
//  Copyright © 2021 MEISHE. All rights reserved.
//

import UIKit

// MARK: - NvMaterialCell

open class NvMaterialCell: NvMaterialDownloadCell {
    
    open func nv_renderCell(for item: NvMaterial, hidden itemTitle: Bool, adjustmentEnabled: Bool = false) {
        selectable = item.selectable
        self.adjustmentEnabled = adjustmentEnabled
        packageId = item.packageId
        titleLabel.isHidden = itemTitle
        titleLabel.text = item.displayName
        if let image = item.coverImage {
            coverImageUrlString = ""
            imageView.nv_setImage(image)
        } else {
            if coverImageUrlString != item.coverUrl {
                imageView.image = nil
            }
            coverImageUrlString = item.coverUrl
            let placeholderImage = NvMaterialUIXEnvs.image(named: "NvDefaultProps")
            imageView.nv_image(urlString: item.coverUrl, placeholderImage: placeholderImage, in: NvMaterialUIXEnvs.moduleBundle())
        }
        let adjustable = item.adjustable
        adjustedImageView.alpha = adjustable ? 1 : 0
        if adjustmentEnabled {
            adjustedTagImageView.isHidden = !adjustable
        } else {
            adjustedTagImageView.isHidden = true
        }
        setDownload(state: item.downloadStatus)
    }
    
    open func nv_setSelected(_ selected: Bool) {
        if selectable,
           selected {
            imageView.layer.borderWidth = NvMaterialUIXEnvs.scale
            titleLabel.startAnimate()
            adjustedImageView.isHidden = !adjustmentEnabled
        } else {
            adjustedImageView.isHidden = true
            imageView.layer.borderWidth = 0
            titleLabel.stopAnimate()
        }
    }
    
    open func setDownload(state: NvMaterialDownloadStatus) {
        if state == .downloading {
            startDownload()
        } else {
            stopDownload()
        }
        
        downloadView.isHidden = state != .none
    }
    
    open override func prepareForReuse() {
        titleLabel.stopAnimate()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        let itemSize = frame.size
        let imageH = itemSize.width > itemSize.height ? itemSize.height : itemSize.width
        imageView = NvAnimatedImageView(frame: CGRect(x: 0,
                                                      y: 0,
                                                      width: itemSize.width,
                                                      height: imageH))
        imageView.contentMode = .center
        imageView.backgroundColor = NvMaterialUIXEnvs.hexColor(hex: "#252525")
        imageView.layer.cornerRadius = 4 * NvMaterialUIXEnvs.scale
        imageView.layer.masksToBounds = true
        imageView.layer.borderColor = NvMaterialUIXEnvs.hexColor(hex: "#FF365E")?.cgColor
        
        titleLabel = NvCarouselLabel(frame: CGRect(x: 0, y: frame.size.width,
                                                   width: itemSize.width,
                                                   height: itemSize.height - frame.size.width))
        titleLabel.font = NvMaterialUIXEnvs.font(size: 10 * NvMaterialUIXEnvs.scale)
        titleLabel.textAlignment = .center
        titleLabel.textColor = NvMaterialUIXEnvs.hexColor(hex: "#D1D1D1")
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.alpha = 0.5
        
        let tagFrame = CGRect(x: imageView.frame.minX + 4 * NvMaterialUIXEnvs.scale,
                              y: imageView.frame.minY + 4 * NvMaterialUIXEnvs.scale,
                              width: 5 * NvMaterialUIXEnvs.scale,
                              height: 5 * NvMaterialUIXEnvs.scale)
        adjustedTagImageView.frame = tagFrame
        adjustedTagImageView.image = NvMaterialUIXEnvs.image(named: "material_cell_adjust_tag")
        adjustedTagImageView.contentMode = .scaleAspectFit
        contentView.addSubview(adjustedTagImageView)
        adjustedTagImageView.isHidden = true

        adjustedImageView.frame = imageView.frame
        adjustedImageView.layer.cornerRadius = 4 * NvMaterialUIXEnvs.scale
        adjustedImageView.layer.masksToBounds = true
        adjustedImageView.image = NvMaterialUIXEnvs.image(named: "material_cell_adjust")
        adjustedImageView.contentMode = .center
        contentView.addSubview(adjustedImageView)
        adjustedImageView.backgroundColor = UIColor(white: 0, alpha: 0.6)
        
        contentView.insertSubview(imageView, at: 0)
        contentView.addSubview(titleLabel)
        
        // —— 未下载标识布局 ——
        let scale = NvMaterialUIXEnvs.scale
        let downloadSize: CGFloat = 13 * scale
        downloadView.frame = CGRect(x: imageView.frame.maxX - downloadSize - 2 * scale,
                                    y: imageView.frame.maxY - downloadSize - 2 * scale,
                                    width: downloadSize,
                                    height: downloadSize)
        downloadView.image = NvMaterialUIXEnvs.image(named: "NvMaterialDownload")
        downloadView.contentMode = .scaleAspectFit
        contentView.addSubview(downloadView)
        downloadView.isHidden = true // 默认隐藏
    }
    
    public var packageId: String = ""
    
    var selectable: Bool = true
    public var imageView = NvAnimatedImageView()
    public var titleLabel = NvCarouselLabel()
    
    var adjustmentEnabled: Bool = false
    public var adjustedImageView = UIImageView()
    public var adjustedTagImageView = UIImageView()
    
    private var coverImageUrlString = ""
    
    public var downloadView = UIImageView() // 未下载标识
    
    @available(*, unavailable)
    required public init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
