//
//  NvAssetRequest.swift
//  MYVideo
//
//  Created by chengww on 2022/2/25.
//

import Foundation
import CryptoKit

public protocol NvMaterialTargetType: NvNetTargetType {
    
    /// 解析 Tab 接口返回数据
    /// Parse response data from Tab API
    func parseTabResponse(_ responseData: Data) -> Result<[NvTabBarCategory], NvRequestError>
    
    /// 解析素材列表接口返回数据
    /// Parse response data from Material list API
    func parseMaterialListResponse(_ responseData: Data) -> Result<(items: [NvMaterial], total: Int, hasMore: Bool), NvRequestError>
}

extension NvMaterialTargetType {
    
    public func parseTabResponse(_ responseData: Data) -> Result<[NvTabBarCategory], NvRequestError> {
        return .failure(.rspError(error: NSError(domain: "Not implemented", code: -5)))
    }
    
    /// 解析素材列表接口返回数据
    /// Parse response data from Material list API
    public func parseMaterialListResponse(_ responseData: Data) -> Result<(items: [NvMaterial], total: Int, hasMore: Bool), NvRequestError> {
        return .failure(.rspError(error: NSError(domain: "Not implemented", code: -5)))
    }
}
