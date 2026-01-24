//
//  NvMaterialListViewLayout.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/6/17.
//

import UIKit

public struct NvMaterialListViewLayout {
    public static func listViewFlowLayout(frame: CGRect,
                                          listParam: NvMaterialListParam) -> UICollectionViewFlowLayout {
        let assetType = listParam.type
        let categoryId = listParam.categoryId ?? 0
        let kindId = listParam.kindId ?? 0
        if assetType == .filter && categoryId == NvMaterialCategory.Fileter.effect.rawValue { /// 特效
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 5 * NvMaterialUIXEnvs.scale
            flowLayout.minimumInteritemSpacing = 5 * NvMaterialUIXEnvs.scale
            let itemW: Double = .init(frame.size.width - 75 * NvMaterialUIXEnvs.scale) / 4.0
            let itemH: Double = .init(24 * NvMaterialUIXEnvs.scale) + itemW
            flowLayout.itemSize = CGSize(width: floor(itemW), height: floor(itemH))
            return flowLayout
        } else if assetType == .filter && categoryId == NvMaterialCategory.Fileter.color.rawValue { /// 滤镜
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumLineSpacing = 10 * NvMaterialUIXEnvs.scale
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.itemSize = CGSize(width: 49 * NvMaterialUIXEnvs.scale, height: 78 * NvMaterialUIXEnvs.scale)
            return flowLayout
        } else if assetType == .filter && categoryId == NvMaterialCategory.Fileter.animation.rawValue {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumLineSpacing = 10 * NvMaterialUIXEnvs.scale
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.itemSize = CGSize(width: 49 * NvMaterialUIXEnvs.scale, height: 78 * NvMaterialUIXEnvs.scale)
            return flowLayout
        } else if assetType == .sticker { /// 贴纸页面
            let flowLayout = UICollectionViewFlowLayout()
            if categoryId == NvMaterialCategory.Sticker.special.rawValue {
                flowLayout.scrollDirection = .vertical
                flowLayout.minimumLineSpacing = 5 * NvMaterialUIXEnvs.scale
                flowLayout.minimumInteritemSpacing = 15 * NvMaterialUIXEnvs.scale
                let itemW: CGFloat = (frame.size.width - 15 * 4 * NvMaterialUIXEnvs.scale - 40 * NvMaterialUIXEnvs.scale) / 5.0
                flowLayout.itemSize = CGSize(width: CGFloat(floorf(Float(itemW))),
                                             height: CGFloat(floorf(Float(itemW))) + 29 * NvMaterialUIXEnvs.scale)
                return flowLayout
            } else if categoryId == NvMaterialCategory.Sticker.animation.rawValue {
                flowLayout.scrollDirection = .horizontal
                flowLayout.minimumLineSpacing = 10 * NvMaterialUIXEnvs.scale
                flowLayout.minimumInteritemSpacing = 10 * NvMaterialUIXEnvs.scale
                flowLayout.itemSize = CGSize(width: 49 * NvMaterialUIXEnvs.scale, height: 78 * NvMaterialUIXEnvs.scale)
            } else {
                flowLayout.scrollDirection = .vertical
                flowLayout.minimumLineSpacing = 12.5 * NvMaterialUIXEnvs.scale
                flowLayout.minimumInteritemSpacing = 15 * NvMaterialUIXEnvs.scale
                let itemW = Double(frame.size.width - 75 * NvMaterialUIXEnvs.scale) / 4.0
                flowLayout.itemSize = CGSize(width: floor(itemW), height: floor(itemW))
            }
            return flowLayout
        } else if assetType == .caption {
            if categoryId == NvMaterialCategory.Caption.normal.rawValue { // 普通字幕
                let flowLayout = UICollectionViewFlowLayout()
                flowLayout.scrollDirection = .vertical
                flowLayout.minimumLineSpacing = 10 * NvMaterialUIXEnvs.scale
                flowLayout.minimumInteritemSpacing = 15 * NvMaterialUIXEnvs.scale
                let itemWH = CGFloat(floorf(Float((NvMaterialUIXEnvs.width - 75 * NvMaterialUIXEnvs.scale) / 4)))
                flowLayout.itemSize = CGSize(width: itemWH, height: itemWH)
                return flowLayout
            } else { // 模块字幕
                if kindId == 1 || kindId == 2 { // 字幕：花字和气泡
                    let flowLayout = UICollectionViewFlowLayout()
                    flowLayout.scrollDirection = .vertical
                    flowLayout.minimumLineSpacing = 10 * NvMaterialUIXEnvs.scale
                    flowLayout.minimumInteritemSpacing = 15 * NvMaterialUIXEnvs.scale
                    let itemWH = CGFloat(floorf(Float((NvMaterialUIXEnvs.width - 75 * NvMaterialUIXEnvs.scale) / 4)))
                    flowLayout.itemSize = CGSize(width: itemWH, height: itemWH)
                    return flowLayout
                } else { // 字幕动画
                    let flowLayout = UICollectionViewFlowLayout()
                    flowLayout.scrollDirection = .horizontal
                    flowLayout.minimumLineSpacing = 10 * NvMaterialUIXEnvs.scale
                    flowLayout.minimumInteritemSpacing = 10 * NvMaterialUIXEnvs.scale
                    flowLayout.itemSize = CGSize(width: 49 * NvMaterialUIXEnvs.scale, height: 78 * NvMaterialUIXEnvs.scale)
                    return flowLayout
                }
            }
        } else if assetType == .compoundCaption { /// 组合字幕
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 12.5 * NvMaterialUIXEnvs.scale
            flowLayout.minimumInteritemSpacing = 15 * NvMaterialUIXEnvs.scale
            let itemW: Double = .init(NvMaterialUIXEnvs.width - 75 * NvMaterialUIXEnvs.scale) / 4.0
            let itemH: Double = .init(45.5 * NvMaterialUIXEnvs.scale)
            flowLayout.itemSize = CGSize(width: floor(itemW), height: itemH)
            return flowLayout
        } else if assetType == .transition {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumLineSpacing = 10 * NvMaterialUIXEnvs.scale
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.itemSize = CGSize(width: 49 * NvMaterialUIXEnvs.scale, height: 78 * NvMaterialUIXEnvs.scale)
            return flowLayout
        } else if assetType == .arscene { /// 人脸道具
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 5 * NvMaterialUIXEnvs.scale
            flowLayout.minimumInteritemSpacing = 5 * NvMaterialUIXEnvs.scale
            let itemW: Double = .init(frame.size.width - 75 * NvMaterialUIXEnvs.scale) / 4.0
            let itemH: Double = .init(24 * NvMaterialUIXEnvs.scale) + itemW
            flowLayout.itemSize = CGSize(width: floor(itemW), height: floor(itemH))
            return flowLayout
            
        } else if assetType == .font { /// 人脸道具
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumLineSpacing = 9 * NvMaterialUIXEnvs.scale
            flowLayout.minimumInteritemSpacing = 9 * NvMaterialUIXEnvs.scale
            flowLayout.itemSize = CGSize(width: 59 * NvMaterialUIXEnvs.scale,
                                         height: 27 * NvMaterialUIXEnvs.scale)
            return flowLayout
        } else {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            flowLayout.minimumLineSpacing = 12.5 * NvMaterialUIXEnvs.scale
            flowLayout.minimumInteritemSpacing = 15 * NvMaterialUIXEnvs.scale
            let itemW: Double = .init(frame.size.width - 75 * NvMaterialUIXEnvs.scale) / 4.0
            flowLayout.itemSize = CGSize(width: floor(itemW), height: floor(itemW))
            return flowLayout
        }
    }
}
