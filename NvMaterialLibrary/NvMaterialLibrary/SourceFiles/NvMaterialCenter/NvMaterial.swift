//
//  NvMaterial.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/6/12.
//

import Foundation
import UIKit

public enum NvMaterialType: Int, Decodable {
    case undefined           = 0        // 为定义
//    case theme               = 1        // 主题
    case filter              = 2        // 滤镜
    case caption              = 3        // 字幕
    case sticker             = 4        // 贴纸
    case transition          = 5        // 转场
//    case particle            = 9        // 粒子
    case arscene             = 14       // 人脸道具
    case compoundCaption     = 15       // 复合字幕
//    case photoAlbum          = 16       // 影集
//    case mimo                = 17       // MIMO
//    case captureTemplate     = 18       // 拍摄模板
    case template            = 19       // 美摄模板
    case makeup              = 20       // 美妆
    case composeMakeup       = 21       // 妆容
    case beautyShape         = 22       // 美型
    case timeFollow          = 23       // 高亮字幕
    case font                = 100001   // 字体
    case waterMark           = 200001   // 水印
}


public enum NvMaterialCategory {
    public enum Fileter: Int {
        case background = 0 // < 滤镜：背景图片（暂时使用0）
        case color = 1 // < 滤镜：调色
        case effect = 2 // < 滤镜：特效
        case animation = 3 // < 滤镜：动画
    }

    public enum Caption: Int {
        case normal = 1 // < 字幕：传统字幕
        case modular = 2 // < 字幕：模块字幕
    }

    public enum Sticker: Int {
        case all = 0
        case normal = 1 // < 贴纸：普通贴纸
        case voice = 2 // < 贴纸：有声贴纸
        case animation = 3 // < 贴纸：动画（需要减1）
        case special = 20000 // < 贴纸：自定义贴纸制作
        case custom = 50000 // < 贴纸：自定义贴纸， 上层自定义的
    }

    public enum ARScene: Int {
        case two // < AR道具：2D
        case three // < AR道具：3D
        case segmentation // < AR道具：分割
        case prospects // < AR道具：前景
        case particle // < AR道具：粒子
    }

    public enum Template: Int {
        case all = 0 // < 所有
        case standard = 1 // < 标准模板
        case theme = 2 // < 自适应时长模板
        case ae = 3 // < AE转换模板
    }
    public enum Makeup: Int {
        /// 口红
        case lip = 1
        /// 眼影
        case eyeshadow
        /// 眉毛
        case eyebrow
        /// 睫毛
        case eyelash
        /// 眼线
        case eyeliner
        /// 腮红
        case blusher
        /// 提亮
        case brighten
        /// 阴影
        case shadow
        /// 美瞳
        case eyeball
    }
}

public enum NvAspectRatio: Int {
    case origin = 0
    case r16v9 = 1
    case r1v1 = 2
    case r9v16 = 4
    case r4v3 = 8
    case r3v4 = 16
    case r18v9 = 32
    case r9v18 = 64
    case rAll = 127
}

public enum NvMaterialDownloadStatus: Int, Codable {
    case none = 0
    case finished = 1
    case downloading = 4
}

open class NvMaterial: Decodable {
    public var type: NvMaterialType = .undefined
    public var category: Int = 0
    public var kind: Int = 0
    
    public var isPostPackage: Bool = false
    public var packageId: String = ""
    public var version: String = ""
    public var displayName: String = ""
    public var coverUrl: String = ""
    public var zipUrl: String = ""
    
    public var adjustable: Bool = false
    
    ///
    public var packagePath: String = ""
    public var licPath: String = ""
    
    public var coverImage: UIImage?
    public var selectable: Bool = true
    
    public var downloadStatus: NvMaterialDownloadStatus = .none
    
    public required init() {}

    enum CodingKeys: String, CodingKey {
        case type, category, kind, id, version, displayName, coverUrl, zipUrl, previewVideoUrl, description, authed, userInfo, adjustable = "isAdjusted"
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decodeIfPresent(NvMaterialType.self, forKey: .type) ?? .undefined
        category = try container.decodeIfPresent(Int.self, forKey: .category) ?? 0
        kind = try container.decodeIfPresent(Int.self, forKey: .kind) ?? 0
        
        if let value = try? container.decodeIfPresent(String.self, forKey: .version), !value.isEmpty {
            version = value
        } else if let value = try? container.decodeIfPresent(Int.self, forKey: .version) {
            version = "\(value)"
        }

        if let value = try? container.decodeIfPresent(String.self, forKey: .id), !value.isEmpty {
            packageId = value
        }

        if let value = try? container.decodeIfPresent(String.self, forKey: .displayName), !value.isEmpty {
            displayName = value
        }

        if let value = try? container.decodeIfPresent(String.self, forKey: .coverUrl), !value.isEmpty {
            coverUrl = value
        }
        
        if let value = try? container.decodeIfPresent(String.self, forKey: .zipUrl), !value.isEmpty {
            zipUrl = value
        }
        
        if let value = try? container.decodeIfPresent(Bool.self, forKey: .adjustable) {
            adjustable = value
        } else if let value = try? container.decodeIfPresent(Int.self, forKey: .adjustable) {
            adjustable = value == 1
        }
        
    }
}

public struct NvMaterialListParam {
    public var type: NvMaterialType
    public var categoryId: Int?
    public var kindId: Int?
    public var optionalParameters: [String: Any]?
    
    public var isAdjusted: Bool?
    
    public init(type: NvMaterialType,
                categoryId: Int? = nil,
                kindId: Int? = nil,
                optionalParameters: [String : Any]? = nil) {
        self.type = type
        self.categoryId = categoryId
        self.kindId = kindId
        self.optionalParameters = optionalParameters
    }
    
    // 实现 Equatable 协议
    public static func == (lhs: NvMaterialListParam, rhs: NvMaterialListParam) -> Bool {
        return lhs.type == rhs.type &&
        lhs.categoryId == rhs.categoryId &&
        lhs.kindId == rhs.kindId
    }
}

public protocol NvTabBarCategory {
    var itemIndicate: String { get }
    var displayName: String { get }
    var listParam: NvMaterialListParam { get }
}


extension NvMaterial {
    
    var needUnzip: Bool {
        switch type {
        case .font:
            return false
        default:
            return true
        }
    }
    
    public static func materialFileExt(type: Int,
                                       categorie: Int?,
                                       kind: Int?) -> [String]? {
        guard let mType = NvMaterialType(rawValue: type) else { return nil }
        switch mType {
        case .undefined:
            log.error("Material type error")
            return nil
        case .filter:
            return ["videofx"]
        case .caption:
            if categorie == NvMaterialCategory.Caption.modular.rawValue {
                guard let kind = kind else {
                    log.error("Material kind error")
                    return nil
                }
                // 模块字幕
                if kind == 1 {
                    // 花字
                    return ["captionrenderer"]
                } else if kind == 2 {
                    // 气泡底图
                    return ["captioncontext"]
                } else if kind == 3 {
                    // 字幕入场动画
                    return ["captioninanimation"]
                } else if kind == 4 {
                    // 字幕出场动画
                    return ["captionoutanimation"]
                } else if kind == 5 {
                    // 字幕组合动画
                    return ["captionanimation"]
                }
            }
            // 传统字幕
            return ["captionstyle"]
        case .sticker:
            if categorie == NvMaterialCategory.Sticker.animation.rawValue {
                guard let kind = kind else {
                    log.error("Material kind error")
                    return nil
                }
                // 贴纸动画
                if kind == 1 {
                    return ["animatedstickerinanimation"]
                } else if kind == 2 {
                    return ["animatedstickeroutanimation"]
                } else if kind == 3 {
                    return ["animatedstickeranimation"]
                }
            }
            return ["animatedsticker"]
        case .template:
            return ["template"]
        case .timeFollow, .composeMakeup:
            return [""]
        case .makeup:
            if categorie == 5 {
                return [""]
            }
            return ["makeup"]
        case .transition:
            return ["transition"]
        case .arscene:
            return ["arscene"]
        case .compoundCaption:
            return ["compoundCaption"]
        case .font:
            return ["ttf", "otf"]
        case .waterMark:
            return []
        case .beautyShape:
            return ["facemesh"]
        }
    }
    
}
