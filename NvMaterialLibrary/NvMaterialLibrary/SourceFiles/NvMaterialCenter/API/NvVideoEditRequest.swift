//
//  NvVideoEditRequest.swift
//  NvMaterialLibrary
//
//  美映网络素材接口
//
//  Created by meishe on 2025/9/2.
//

#if canImport(NvEffectSdkCore)
import NvEffectSdkCore
#elseif canImport(NvStreamingSdkCore)
import NvStreamingSdkCore
#endif

public enum NvVideoEditRequest {
    // 商城素材 / Mall material
    case mallCategory(listParams: [NvMaterialListParam] = [])
    // 商城素材列表 / Mall material list
    case mall(listParam: NvMaterialListParam, page: Int, pageSize: Int = 20, ratio: Int = 0, keyword: String? = nil)
}

extension NvVideoEditRequest: NvMaterialTargetType {

    public var url: String {
        let mall_base_url = "https://creative.meishesdk.com/api/app"
        
        let path: String
        switch self {
        case .mall: path = "/material/listPublic"
        case .mallCategory: path = "/material/listClassTree"
        }
        return mall_base_url + path
    }
    
    public var method: NvHttpMethod {
        .get
    }
    
    public var paramInfo: (urlParameters: [String: Any]?, bodyParameters: Any?) {
        switch self {
        case let .mall(listParam, page, pageSize, ratio, keyword):
            var map = generalParameters()
            map["pageNum"] = page
            map["pageSize"] = pageSize
            let type = listParam.type.rawValue
            if type != 19 {
                map["ratioFlag"] = 1
            } else {
                map["needInteractive"] = 1
            }
            //            if ratio != 0 {
            //                map["supportedAspectRatio "] = ratio
            //            }
            if type != 0 {
                map["type"] = type
            }
            if let categoryId = listParam.categoryId, categoryId > 0 {
                map["category"] = categoryId
            }
            if let kindId = listParam.kindId, kindId > 0 {
                map["kind"] = kindId
            }
            if let keyword = keyword {
                map["keyword"] = keyword
            }
            if let isAdjusted = listParam.isAdjusted {
                map["isAdjusted"] = listParam.isAdjusted
            }
            return (urlParameters: map, bodyParameters: nil)
        case let .mallCategory(listParams):
            var map = generalParameters()
            var types: [String] = []
            var categories: [String] = []
            for item in listParams {
                types.append(String(item.type.rawValue))
                if let categoryId = item.categoryId, categoryId > 0 {
                    categories.append(String(categoryId))
                }
            }
            if !types.isEmpty {
                map["types"] = types.joined(separator: ",")
            }
            if !categories.isEmpty {
                map["categories"] = categories.map { String($0) }.joined(separator: ",")
            }
            return (urlParameters: map, bodyParameters: nil)
        }
    }
    
    public var normalCode: Int { 0 }
    
    public var responseType: Decodable.Type {
        switch self {
        case let .mall:
            return [NvVideoEditResponseTabItem].self
        case let .mallCategory:
            return NvMaterialListResponse<NvMaterial>.self
        }
    }
    
    func currentLang() -> String {
        let currentLang = Locale.preferredLanguages.first ?? "en"
        var lang = "en"
        let languageCodes = ["en", "zh", "es", "ar", "de", "el", "fi", "fr", "hi", "id", "it", "ja", "ko", "nl", "pl", "pt", "ru", "tr", "he", "sv"]
        
        for code in languageCodes {
            if currentLang.hasPrefix(code) {
                if code == "zh" {
                    lang = "zh_cn"
                } else {
                    lang = code
                }
                break
            }
        }
        
        return lang
    }
    
    private func generalParameters() -> [String: Any] {
        var map: [String: Any] = [:]
        map["sdkVersion"] = NvVideoEditRequest.sdkVersion()
        map["lang"] = currentLang()
        if let bundleID = Bundle.main.bundleIdentifier {
            map["appId"] = bundleID
        } else {
            log.error("无法获取 Bundle ID")
        }
        return map
    }
    
    public var headers: [String: String]? {
        /// 接口加密
        let secretId = "174709A4-DF3D-7291"
        let secretKey = "66AD08B1-DCCD-A3FD-154E-5C7AED30FA16"
        
        guard let requestUrl = URL(string: url), let host = requestUrl.host else { return nil }
        let nonce = UUID().uuidString
        let timeMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let pInfo = paramInfo
        let params = pInfo.urlParameters
        return NvAuth.generateHeaders(
            secretId: secretId,
            secretKey: secretKey,
            method: method.rawValue,
            host: host,
            params: params ?? [:],
            token: nil,
            nonce: nonce,
            timeMillis: timeMillis
        )
    }
    
    public static func sdkVersion() -> String {
        var majorVersion: Int32 = 0
        var minorVersion: Int32 = 0
        var revisionNumber: Int32 = 0
        
#if canImport(NvEffectSdkCore)
        NvsEffectSdkContext.getSdkVersion(&majorVersion, minorVersion: &minorVersion, revisionNumber: &revisionNumber)
#elseif canImport(NvStreamingSdkCore)
        NvsStreamingContext.getSdkVersion(&majorVersion, minorVersion: &minorVersion, revisionNumber: &revisionNumber)
#endif
        
        return "\(majorVersion).\(minorVersion).\(revisionNumber)"
    }
    
    // MARK: -- Parse response
    public func parseTabResponse(_ responseData: Data) -> Result<[NvTabBarCategory], NvRequestError> {
        if case .mall = self {
            return .failure(.rspError(error: NSError(domain: "Not implemented", code: -5)))
        } else if case let .mallCategory(listParams) = self {
            var forEditModule = true
            if let listParam = listParams.first,
               listParam.type == .filter,
               listParam.optionalParameters?["module"] != nil {
                forEditModule = false
            }
            if let json = try? JSONSerialization
                .jsonObject(with: responseData, options: .allowFragments) as? [String: Any],
               let categoryResponse = NvCodableJSON.mapToModel(map: json, modelType: NvVideoEditCategoryResponse.self) {
                if categoryResponse.code == normalCode {
                    if let firstTab = categoryResponse.data.first, !firstTab.items.isEmpty {
                        if case let .mallCategory(listParams) = self,
                           let param = listParams.first,
                           param.categoryId != 0 {
                            return .success(firstTab.parseTabs(categoryId: param.categoryId, forEditModule: forEditModule))
                        }
                        return .success(firstTab.parseTabs())
                    } else {
                        return .success([])
                    }
                } else {
                    return .failure(.rspError(error: NSError(domain: categoryResponse.msg, code: categoryResponse.code)))
                }
            }
        }
        return .failure(.rspError(error: NSError(domain: "mapToModel error", code: -4)))
        
    }
    
    /// 解析素材列表接口返回数据
    /// Parse response data from Material list API
    public func parseMaterialListResponse(_ responseData: Data) -> Result<(items: [NvMaterial], total: Int, hasMore: Bool), NvRequestError> {
        if case let .mallCategory = self {
            return .failure(.rspError(error: NSError(domain: "Not implemented", code: -5)))
        }
        if let json = try? JSONSerialization.jsonObject(with: responseData,
                                                        options: .allowFragments) as? [String: Any],
           let listResponse = NvCodableJSON.mapToModel(map: json,
                                                       modelType: NvResponse<NvMaterialListResponse<NvMaterial>>.self) {
            if listResponse.code == normalCode {
                guard let resultData = listResponse.data else {
                    return .failure(.rspError(error: NSError(domain: "categoryResponse data nil", code: -5)))
                }
                return .success((items: resultData.elements, total: resultData.total, hasMore: true))
            } else {
                return .failure(.rspError(error: NSError(domain: listResponse.msg, code: listResponse.code)))
            }
        } else {
            return .failure(.rspError(error: NSError(domain: "mapToModel error", code: -4)))
        }
    }
}

//public extension NvVideoEditRequest {
//    public func parseResponse<T: Decodable>(data: Data) -> Result<T, NvRequestError> {
//        let json = try? JSONSerialization.jsonObject(with: data,
//                                                     options: .allowFragments) as? [String: Any]
//        if let json = json,
//           let response = NvCodableJSON.mapToModel(map: json, modelType: NvResponse<T>.self) {
//            if response.code == normalCode {
//                return .success(response.data)
//            } else {
//                let error = NSError(domain: "rsp error",
//                                    code: -3,
//                                    userInfo: [NSLocalizedDescriptionKey : response.message])
//                return .failure(.rspError(error: error))
//            }
//        } else {
//            log.error("JSONSerialization error:\n\(json)")
//            return .failure(.rspError(error: NSError(domain: "mapToModel error", code: -4)))
//        }
//    }
//}
