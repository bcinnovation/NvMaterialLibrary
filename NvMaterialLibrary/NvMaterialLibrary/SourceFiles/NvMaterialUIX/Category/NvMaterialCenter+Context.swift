//
//  NvMaterialCenter+Context.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/1.
//

#if canImport(NvEffectSdkCore)
import NvEffectSdkCore
#elseif canImport(NvStreamingSdkCore)
import NvStreamingSdkCore
#endif

extension NvMaterial {
    
    public static func materialType(type: Int,
                                    categorie: Int?,
                                    kind: Int?) -> NvsAssetPackageType? {
        guard let mType = NvMaterialType(rawValue: type) else { return nil }
        switch mType {
        case .undefined:
            log.error("Material type error")
            return nil
        case .filter:
            return NvsAssetPackageType_VideoFx
        case .caption:
            if categorie == NvMaterialCategory.Caption.modular.rawValue {
                guard let kind = kind else {
                    log.error("Material kind error")
                    return nil
                }
                // 模块字幕
                if kind == 1 {
                    // 花字
                    return NvsAssetPackageType_CaptionRenderer
                } else if kind == 2 {
                    // 气泡底图
                    return NvsAssetPackageType_CaptionContext
                } else if kind == 3 {
                    // 字幕入场动画
                    return NvsAssetPackageType_CaptionInAnimation
                } else if kind == 4 {
                    // 字幕出场动画
                    return NvsAssetPackageType_CaptionOutAnimation
                } else if kind == 5 {
                    // 字幕组合动画
                    return NvsAssetPackageType_CaptionAnimation
                }
            }
            // 传统字幕
            return NvsAssetPackageType_CaptionStyle
        case .sticker:
            if categorie == NvMaterialCategory.Sticker.animation.rawValue {
                guard let kind = kind else {
                    log.error("Material kind error")
                    return nil
                }
                // 贴纸动画
                if kind == 1 {
                    return NvsAssetPackageType_AnimatedStickerInAnimation
                } else if kind == 2 {
                    return NvsAssetPackageType_AnimatedStickerOutAnimation
                } else if kind == 3 {
                    return NvsAssetPackageType_AnimatedStickerAnimation
                }
            }
            return NvsAssetPackageType_AnimatedSticker
        case .template:
            return NvsAssetPackageType_Template
        case .timeFollow, .composeMakeup:
            return nil
        case .makeup:
            if categorie == 5 {
                return nil
            }
            return NvsAssetPackageType_Makeup
        case .transition:
            return NvsAssetPackageType_VideoTransition
        case .arscene:
            return NvsAssetPackageType_ARScene
        case .compoundCaption:
            return NvsAssetPackageType_CompoundCaption
        case .font:
            return nil
        case .beautyShape:
            return NvsAssetPackageType_FaceMesh
        case .waterMark:
            log.error("Material type error")
            return nil
        }
    }
    
}

extension NvMaterialCenter {
    
    /// Synchronous install or upgrade the package if new version is higher than old version
    /// - Remark: 同步安装资源，如果安装的版本高于上次的就升级安装包
    /// - Parameters:
    ///   - packagePath: the path of package
    ///   - license: the path of licence
    ///   - assetType: the type of package
    ///   - installComplete: callback the install result for packageId and install state
    public static func syncInstallPackage(packagePath: String,
                                          license: String,
                                          type: NvsAssetPackageType) -> (suc: Bool, packageId: String) {
        if !FileManager.default.fileExists(atPath: packagePath) {
            log.error("syncInstallPackage fileExists:\(packagePath)")
            return (suc: false, packageId: "")
        }
#if canImport(NvEffectSdkCore)
        let context = NvsEffectSdkContext.sharedInstance(NvsEffectSdkContextFlag_NoFlag)
#elseif canImport(NvStreamingSdkCore)
        let context = NvsStreamingContext.sharedInstance()
#endif
        
        guard let assetManager = context?.assetPackageManager else {
            return (suc: false, packageId: "")
        }
        let packageId = assetManager.getAssetPackageId(fromAssetPackageFilePath: packagePath)
        let lastVersion = assetManager.getAssetPackageVersion(packageId, type: type)
        let newViersion = assetManager.getAssetPackageVersion(fromAssetPackageFilePath: packagePath)
        let pid = NSMutableString()
        if newViersion > lastVersion { // 升级
            assetManager.uninstallAssetPackage(packageId, type: type)
            let err = assetManager.installAssetPackage(packagePath, license: license, type: type, sync: true,
                                                       assetPackageId: pid)
            if err == NvsAssetPackageManagerError_NoError || err == NvsAssetPackageManagerError_AlreadyInstalled {
                return (suc: true, packageId: pid as String)
            } else {
                if err == NvsAssetPackageManagerError_Permission {
                    log.error("""
                    ⚠️ Important Notice ⚠️
                    Please purchase or redeem the effect pack: \(packagePath)
                    lic: \(license)
                    For instructions, please visit:
                    https://www.meishesdk.com/web/front_end/html/sdk-material-auth/Material.html
                    """)
                } else {
                    log.error("syncInstallPackage error:\npackagePath:\(packagePath)\nlicense:\(license)\nerr:\(err)")
                }
                return (suc: false, packageId: "")
            }
        } else {
            let err = assetManager.installAssetPackage(packagePath,
                                                       license: license,
                                                       type: type,
                                                       sync: true,
                                                       assetPackageId: pid)
            if err == NvsAssetPackageManagerError_NoError || err == NvsAssetPackageManagerError_AlreadyInstalled {
                return (suc: true, packageId: pid as String)
            } else {
                if err == NvsAssetPackageManagerError_Permission {
                    log.error("""
                    ⚠️ Important Notice ⚠️
                    Please purchase or redeem the effect pack: \(packagePath)
                    lic: \(license)
                    For instructions, please visit:
                    https://www.meishesdk.com/web/front_end/html/sdk-material-auth/Material.html
                    """)
                } else {
                    log.error("syncInstallPackage error:\npackagePath:\(packagePath)\nlicense:\(license)\nerror:\(err)")
                }
                return (suc: false, packageId: "")
            }
        }
    }
}
