//
//  NvMaterialCenterNetManager.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/6/12.
//

import UIKit

/// 素材中心网络请求协议 / Material center network protocol
/// 将所有网络相关操作从库中解耦，使库专注于素材管理逻辑，网络实现由使用方提供
/// Decouples all network operations from the library, focusing the library on material management; network implementation is provided by the client
///
/// **设计目的 / Design goals:**
/// 1. 网络框架解耦 / Decouple network framework: clients can choose any framework (Alamofire, URLSession, etc.)
/// 2. 业务逻辑定制 / Customizable business logic: handle authentication, signing, error processing
/// 3. 测试友好 / Test-friendly: easy to mock network requests for unit testing
/// 4. 库体积优化 / Library size optimization: avoid strong dependencies on third-party network libraries
public protocol NvMaterialCenterNetManager {
    
    /// 请求素材分类列表 / Request material categories
    ///
    /// 发送网络请求获取素材分类列表，并在完成后通过回调返回结果
    /// Sends a network request to fetch material categories and returns the result via callback
    ///
    /// - Parameters:
    ///   - target: 请求目标类型 / The target request type (defines API endpoint, parameters, method, headers, etc.)
    ///   - completion: 请求完成回调 / Completion callback
    ///     - Result.success: 返回素材分类列表 / Returns an array of categories
    ///     - Result.failure: 返回请求或解析错误 / Returns an error
    /// - Note: 实现方需要处理 API 调用、数据解析和错误处理 / Implementers should handle API calls, data parsing, and error handling
    func requestCategory(
        target: NvMaterialTargetType,
        completion: @escaping (Result<[NvTabBarCategory], NvRequestError>) -> Void
    )
    
    /// 请求素材列表 / Request material list
    ///
    /// 发送网络请求获取素材列表，并支持分页加载，完成后通过回调返回结果
    /// Sends a network request to fetch materials with pagination and returns the result via callback
    ///
    /// - Parameters:
    ///   - target: 请求目标类型 / The target request type (defines API endpoint, parameters, method, headers, etc.)
    ///   - completion: 请求完成回调 / Completion callback
    ///     - Result.success: 返回素材数组、总数及是否有更多 / Returns materials array, total count, and hasMore flag
    ///     - Result.failure: 返回请求或解析错误 / Returns an error
    /// - Note: 支持分页加载，实现方需要处理分页逻辑和数据解析 / Supports pagination; implementers should handle pagination and parsing
    func requestMaterial(
        target: NvMaterialTargetType,
        completion: @escaping (Result<(items: [NvMaterial], total: Int, hasMore: Bool), NvRequestError>) -> Void
    )
    
    /// 下载素材包到本地 / Download material package locally
    /// - Parameters:
    ///   - material: 要下载的素材信息 / Material to download
    ///   - targetDirPath: 目标下载目录的绝对路径 / Absolute path of target download directory
    ///   - progress: 下载进度回调（0.0-1.0）/ Download progress callback (0.0-1.0)
    ///   - completion: 下载完成回调，返回下载后的文件路径 / Completion callback with downloaded file URL
    /// - Note: 实现方需要处理文件下载、解压缩、许可证处理等操作 / Implementers should handle download, unzipping, and license processing
    /// - Important: 下载完成后需要将文件解压到指定目录，并返回正确的文件路径 / Ensure the file is unzipped to the target directory and return the correct file path
    func download(material: NvMaterial,
                  progress: @escaping (Double) -> Void,
                  completion: @escaping (Result<URL, NvRequestError>) -> Void) -> NvCancellable?
    
}
