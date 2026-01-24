//
//  NvMaterialCenter.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/6/12.
//

import Foundation

public protocol NvMaterialDownloadStateDelegate: AnyObject {
    
    /// 下载进度回调
    /// @param packageId 资源id
    /// @param progress 进度
    func materialCenter(packageId: String,
                        type: NvMaterialType,
                        categorie: Int,
                        kind: Int,
                        download progress: Double)

    /// 下载状态变化回调
    /// @param packageId 资源id
    /// @param state 下载状态
    /// @param error 错误信息
    func materialCenterDownloadCompleted(packageId: String,
                                         type: NvMaterialType,
                                         categorie: Int,
                                         kind: Int,
                                         result: Result<(packagePath: String, licPath: String), NvRequestError>)
    
}

public let log = NvLogger.with("NvMaterialCenter")

public class NvMaterialCenter {
    
    public var netOperator: NvMaterialCenterNetManager
    
    public let materialDir: String = "/Documents/material/"
    
    public let transferManager = NvTransferManager()
    
    private static var _sharedInstance: NvMaterialCenter?
    public class func shared() -> NvMaterialCenter {
        if let manager = _sharedInstance {
            return manager
        }
        let manager = NvMaterialCenter()
        _sharedInstance = manager
        
        
        return manager
    }

    public class func destoryInstance() {
        _sharedInstance = nil
        NvLogger.dispose("NvMaterialCenter")
    }
    
    private init() {
        self.netOperator = NvMaterialCenterDefaultNetManager()
    }
    
    lazy var database: NvMaterialDatabase = {
        let downloadMaterialDir = NSHomeDirectory() + materialDir
        let fm = FileManager.default
        if !fm.fileExists(atPath: downloadMaterialDir) {
            try? fm.createDirectory(atPath: downloadMaterialDir, withIntermediateDirectories: true)
        }
        let dbPath = "\(downloadMaterialDir)material_database.sqlite"
        return NvMaterialDatabase(dbPath: dbPath)
    }()
    
    // MARK: -- Public
    
    /// 请求素材分类列表
    /// - Parameters:
    ///   - target: 素材列表参数，包含类型、分类ID等
    ///   - completion: 完成回调，返回分类列表或错误
    /// - Note: 需要设置netDelegate才能正常工作
    public func requestCategory(target: NvMaterialTargetType,
                                completion: @escaping (Result<[NvTabBarCategory], NvRequestError>) -> Void) {
        nv_requestCategory(target: target, completion: completion)
    }
    
    /// 请求素材列表
    /// - Parameters:
    ///   - target: 素材列表参数，包含类型、分类ID等
    ///   - completion: 完成回调，返回素材列表、总数和是否有更多数据
    /// - Note: 会自动检查并设置本地下载状态
    public func requestMaterial(target: NvMaterialTargetType,
                                completion: @escaping (Result<(items: [NvMaterial], total: Int, hasMore: Bool), NvRequestError>) -> Void) {
        nv_requestMaterial(target: target,
                           completion: completion)
    }
    
    // MARK: -- 下载相关方法 NvMaterialDownloadState
    
    public func materialIsInProcess(packageId: String) -> Bool {
        return processingQueue.sync {
            return processingMaterials.keys.contains(packageId)
        }
    }
    
    /// 下载素材包
    /// - Parameter material: 要下载的素材对象
    /// - Returns: 是否成功开始下载。返回false可能是因为已在下载中或netDelegate未设置
    /// - Note: 使用NvMaterialDownloadStateDelegate监听下载进度和完成状态
    public func download(material: NvMaterial) -> Bool {
        return nv_download(material: material)
    }
    
    public func download(material: NvMaterial,
                         progress: @escaping (Double) -> Void,
                         completion: @escaping (Result<URL, NvRequestError>) -> Void) -> NvCancellable? {
        return nv_download(material: material, progress: progress, completion: completion)
    }
    
    /// 注册下载状态回调观察者
    /// - Parameter observer: 实现NvMaterialDownloadStateDelegate协议的观察者
    /// - Note: 使用弱引用，无需手动移除
    public func add(observer item: NvMaterialDownloadStateDelegate) {
        delegateQueue.async(flags: .barrier) {
            if let object = item as? AnyObject {
                self.downloadDelegateSet.add(object)
            }
        }
    }
    
    /// 移除下载状态回调观察者
    /// - Parameter observer: 要移除的观察者
//    public func remove(observer: NvMaterialDownloadStateDelegate) {
//        delegateQueue.async(flags: .barrier) {
//            if let object = observer as? AnyObject {
//                self.downloadDelegateSet.remove(object)
//            }
//        }
//    }
    
    // MARK: - Database Methods
    
    /// 根据包ID查询已下载的素材信息
    /// - Parameter packageId: 素材包的唯一标识符
    /// - Returns: 素材对象，如果未找到或未下载返回nil
    /// - Note: 返回的素材对象包含完整的路径信息
    public func getMaterial(packageId: String) -> NvMaterial? {
        return database.getMaterial(packageId: packageId)
    }
    
    public func getMaterials(packageIds: [String]) -> [String: NvMaterial] {
        return database.getMaterials(packageIds: packageIds)
    }
    
    /// 检查素材是否已下载到本地
    /// - Parameter packageId: 素材包的唯一标识符
    /// - Returns: true表示已下载，false表示未下载
    public func isMaterialDownloaded(packageId: String) -> Bool {
        return database.isDownloaded(packageId: packageId)
    }
    
    /// 获取已下载到本地的素材列表
    /// - Parameter type: 素材类型过滤条件，传nil返回所有类型
    /// - Returns: 已下载的素材数组，按下载时间倒序排列
    public func getDownloadedMaterials(type: NvMaterialType? = nil) -> [NvMaterial] {
        return database.getDownloadedMaterials(type: type)
    }
    
    /// 批量检查多个素材的下载状态
    /// - Parameter packageIds: 要检查的素材ID数组
    /// - Returns: 字典，key为packageId，value为是否已下载
    /// - Note: 相比逐个检查，批量检查性能更好
    public func batchGetDownloadedPathsAsync(
        items: [(packageId: String, version: String)],
        completion: @escaping ([String: (packagePath: String, licPath: String)]) -> Void) {
        database.batchGetDownloadedPathsAsync(items: items, completion: completion)
    }
    
    /// 删除已下载的素材记录（不删除文件）
    /// - Parameter packageId: 要删除记录的素材ID
    /// - Returns: 是否删除成功
    /// - Warning: 此方法只删除数据库记录，不会删除实际文件
    public func deleteMaterial(packageId: String) -> Bool {
        return database.deleteMaterial(packageId: packageId)
    }
    
    // MARK: - Font Management
    
    /// 保存字体包的family name映射关系
    /// - Parameters:
    ///   - packageId: 字体包ID
    ///   - familyNames: 字体family name数组（如["Arial", "Arial-Bold"]）
    /// - Returns: 是否保存成功
    /// - Note: 会先删除该字体包的旧映射再保存新映射
    public func saveFontFamilyMapping(packageId: String, familyNames: [String]) -> Bool {
        return database.saveFontFamilyMapping(packageId: packageId, familyNames: familyNames)
    }
    
    /// 根据字体family name查询对应的字体包信息
    /// - Parameter familyName: 字体family name（如"Arial"）
    /// - Returns: 包含该字体的字体包信息，未找到返回nil
    /// - Note: 用于根据字体名称快速定位字体包
    public func getFontPackage(byFamilyName familyName: String) -> NvMaterial? {
        return database.getFontPackage(byFamilyName: familyName)
    }
    
    /// 获取字体包包含的所有字体family names
    /// - Parameter packageId: 字体包ID
    /// - Returns: 字体family name数组
    public func getFontFamilyNames(packageId: String) -> [String] {
        return database.getFontFamilyNames(packageId: packageId)
    }
    
    /// 检查指定的字体family name是否已存在
    /// - Parameter familyName: 要检查的字体family name
    /// - Returns: true表示已存在，false表示不存在
    public func isFontFamilyExists(familyName: String) -> Bool {
        return database.isFontFamilyExists(familyName: familyName)
    }
    
    /// 删除字体包的所有family name映射
    /// - Parameter packageId: 字体包ID
    /// - Returns: 是否删除成功
    public func deleteFontFamilyMapping(packageId: String) -> Bool {
        return database.deleteFontFamilyMapping(packageId: packageId)
    }
    
    
    private var downloadDelegateSet = NSHashTable<AnyObject>.weakObjects()
    private let delegateQueue = DispatchQueue(label: "com.nvmaterial.delegate", attributes: .concurrent)
    
    var processingMaterials = [String: NvMaterial]()
    let processingQueue = DispatchQueue(label: "com.nvmaterial.processing", attributes: .concurrent)
}

extension NvMaterialCenter {
    
    private func nv_download(material: NvMaterial) -> Bool {
        if materialIsInProcess(packageId: material.packageId) {
            material.downloadStatus = .downloading
            return true
        }
        material.downloadStatus = .downloading
        
        let downloadMaterialDir = NSHomeDirectory() + materialDir
        let fm = FileManager.default
        if !fm.fileExists(atPath: downloadMaterialDir) {
            try? fm.createDirectory(atPath: downloadMaterialDir, withIntermediateDirectories: true)
        }
        netOperator.download(material: material) { progress in
            self.updateDownload(packageId: material.packageId, progress: progress)
        } completion: { result in
            self.downloadCompleted(packageId: material.packageId, result: result)
        }
        
        processingQueue.async(flags: .barrier) {
            self.processingMaterials[material.packageId] = material
        }
        return true
    }
    
    func nv_download(material: NvMaterial,
                  progress: @escaping (Double) -> Void,
                  completion: @escaping (Result<URL, NvRequestError>) -> Void) -> NvCancellable? {
        if materialIsInProcess(packageId: material.packageId) {
            material.downloadStatus = .downloading
            return nil
        }
        material.downloadStatus = .downloading
        
        let downloadMaterialDir = NSHomeDirectory() + materialDir
        let fm = FileManager.default
        if !fm.fileExists(atPath: downloadMaterialDir) {
            try? fm.createDirectory(atPath: downloadMaterialDir, withIntermediateDirectories: true)
        }
        processingQueue.async(flags: .barrier) {
            self.processingMaterials[material.packageId] = material
        }
        return netOperator.download(material: material) { p in
            self.updateDownload(packageId: material.packageId, progress: p)
            progress(p)
        } completion: { result in
            self.downloadCompleted(packageId: material.packageId, result: result)
            completion(result)
        }
    }
    
    private func updateDownload(packageId: String, progress: Double) {
        var material: NvMaterial?
        var delegates: [NvMaterialDownloadStateDelegate] = []
        
        // 读取数据
        processingQueue.sync {
            material = self.processingMaterials[packageId]
        }
        
        delegateQueue.sync {
            for case let observer as NvMaterialDownloadStateDelegate in self.downloadDelegateSet.allObjects {
                delegates.append(observer)
            }
        }
        
        // 主线程回调
        DispatchQueue.main.async {
            if let item = material {
                for weakDelegate in delegates {
                    weakDelegate.materialCenter(packageId: packageId,
                                                       type: item.type,
                                                       categorie: item.category,
                                                       kind: item.kind,
                                                       download: progress)
                }
            }
        }
    }
    
    private func downloadCompleted(packageId: String,
                                   result: Result<URL, NvRequestError>) {
        var material: NvMaterial?
        var delegates: [NvMaterialDownloadStateDelegate] = []

        // 移除处理中的素材并获取数据
        processingQueue.sync(flags: .barrier) {
            material = self.processingMaterials.removeValue(forKey: packageId)
        }

        delegateQueue.sync {
            for case let observer as NvMaterialDownloadStateDelegate in self.downloadDelegateSet.allObjects {
                delegates.append(observer)
            }
        }

        var callbackResult: Result<(packagePath: String, licPath: String), NvRequestError>?

        // 处理下载结果
        if let item = material {
            switch result {
            case .success(let downloadFile):
                if let fileInfo = processDownloadedMaterial(item, fileAt: downloadFile) {
                    // 下载成功时保存到数据库
                    database.recordDownload(material: item, packagePath: fileInfo.packagePath, licPath: fileInfo.licPath) { ret in
                        if !ret {
                            log.error("Failed to record download to database - packageId: \(packageId), displayName: \(item.displayName), packagePath: \(fileInfo.packagePath), licPath: \(fileInfo.licPath)")
                        }
                    }
                    item.downloadStatus = .finished
                    callbackResult = .success((packagePath: fileInfo.packagePath, licPath: fileInfo.licPath))
                } else {
                    item.downloadStatus = .none
                    // 文件处理失败
                    let error = NSError(domain: "NvMaterialErrorDomain",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Failed to process downloaded material"])
                    callbackResult = .failure(.rspError(error: error))
                }
            case .failure(let error):
                item.downloadStatus = .none
                // 下载失败时打印错误信息
                log.error("Material download failed - packageId: \(packageId), displayName: \(item.displayName), error: \(error)")
                callbackResult = .failure(error)
            }
        } else {
            // 找不到素材
            let error = NSError(domain: "NvMaterialErrorDomain",
                                code: -2,
                                userInfo: [NSLocalizedDescriptionKey: "Material not found for packageId \(packageId)"])
            callbackResult = .failure(.rspError(error: error))
        }

        // 主线程回调
        DispatchQueue.main.async {

            if let item = material, let finalResult = callbackResult {
                for weakDelegate in delegates {
                    weakDelegate.materialCenterDownloadCompleted(packageId: packageId,
                                                                        type: item.type,
                                                                        categorie: item.category,
                                                                        kind: item.kind,
                                                                        result: finalResult)
                }
            }
        }
    }
    
}
