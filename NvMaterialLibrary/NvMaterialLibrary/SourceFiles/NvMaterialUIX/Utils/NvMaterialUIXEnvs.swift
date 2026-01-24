//
//  NvMaterialUIXEnvs.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/6/16.
//


import UIKit

// MARK: - 字体和颜色

public enum NvMaterialUIXEnvs {
    
    public static func font(size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size)
    }

    static func rgbColor(r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: alpha)
    }

    public static func hexColor(hex: String, alpha: CGFloat = 1.0) -> UIColor? {
        guard hex.count >= 6 else {
            return nil
        }
        var hexString = hex.uppercased()
        if hexString.hasPrefix("##") || hexString.hasPrefix("0x") {
            hexString = (hexString as NSString).substring(from: 2)
        }
        if hexString.hasPrefix("#") {
            hexString = (hexString as NSString).substring(from: 1)
        }
        var range = NSRange(location: 0, length: 2)
        let rStr = (hexString as NSString).substring(with: range)
        range.location = 2
        let gStr = (hexString as NSString).substring(with: range)
        range.location = 4
        let bStr = (hexString as NSString).substring(with: range)
        var r: UInt32 = 0
        var g: UInt32 = 0
        var b: UInt32 = 0
        Scanner(string: rStr).scanHexInt32(&r)
        Scanner(string: gStr).scanHexInt32(&g)
        Scanner(string: bStr).scanHexInt32(&b)
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }
}

// MARK: - 国际化

extension NvMaterialUIXEnvs {

    public static func localizedString(key: String, comment: String) -> String {
        guard let languageStr = NSLocale.preferredLanguages.first else {
            return key
        }
        var s = comment
        var language = "en"
        if languageStr.hasPrefix("zh-") {
            language = "zh-Hans"
        }
        if let path = assetBundle()?.path(forResource: language, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            s = languageBundle.localizedString(forKey: key, value: comment, table: "NvMaterialUIX")
        }
        return Bundle.main.localizedString(forKey: key, value: s, table: "NvMaterialUIX")
    }
}

// MARK: - 资源

extension NvMaterialUIXEnvs {
    
    static public func moduleBundle() -> Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        return Bundle(for: NvMaterialCenter.self)
#endif
    }
    
    static func assetBundle() -> Bundle? {
        if let path = moduleBundle().path(forResource: "NvMaterialUIX", ofType: "bundle") {
            return Bundle(path: path)
        }
        return nil
    }

    static func image(named name: String) -> UIImage {
        if name.isEmpty {
            return UIImage()
        }
        let image = UIImage(named: name, in: moduleBundle(), compatibleWith: nil) ??
            nil
        if image == nil {
            return UIImage(named: name)?.withRenderingMode(.alwaysOriginal) ?? UIImage()
        } else {
            return image?.withRenderingMode(.alwaysOriginal) ?? UIImage()
        }
    }
}

// MARK: - 布局参数

extension NvMaterialUIXEnvs {
    public static var width: CGFloat { nv_appEnvs(envs: .width) }

    public static var height: CGFloat { nv_appEnvs(envs: .height) }

    public static var scale: CGFloat { nv_appEnvs(envs: .scale) }

    public static var statusBarHeight: CGFloat { nv_appEnvs(envs: .statusBarHeight) }

    public static var naviBarHeight: CGFloat { nv_appEnvs(envs: .naviBarHeight) }

    public static var naviHeight: CGFloat { nv_appEnvs(envs: .naviHeight) }

    public static var bottomSafeAreaHeight: CGFloat { nv_appEnvs(envs: .bottomSafeAreaHeight) }
}

extension NvMaterialUIXEnvs {

    enum NvEnvs {
        case width
        case height
        case scale
        case statusBarHeight
        case naviBarHeight
        case naviHeight
        case bottomSafeAreaHeight
    }

    private static func nv_appEnvs(envs: NvEnvs) -> CGFloat {
        var value: CGFloat = 0.0
        switch envs {
        case .width:
            value = UIScreen.main.bounds.size.width
        case .height:
            value = UIScreen.main.bounds.size.height
        case .scale:
            value = UIScreen.main.bounds.size.width / 375.0
        case .statusBarHeight:
            value = UIApplication.shared.statusBarFrame.size.height
        case .naviBarHeight:
            value = 44.0
        case .naviHeight:
            value = UIApplication.shared.statusBarFrame.size.height + 44.0
        case .bottomSafeAreaHeight:
            value = UIApplication.shared.statusBarFrame.size.height > 20 ? 34.0 : 0.0
        }
        return value
    }
    
}
