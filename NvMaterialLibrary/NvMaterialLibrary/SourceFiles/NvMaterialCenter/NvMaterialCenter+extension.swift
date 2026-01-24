//
//  NvMaterialCenter+extension.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/6/12.
//

import Foundation
import Zip

extension NvMaterialCenter {
    
    public func nv_requestCategory(target: NvMaterialTargetType,
                                   completion: @escaping (Result<[NvTabBarCategory], NvRequestError>) -> Void) {
        netOperator.requestCategory(target: target, completion: completion)
    }
    
    func nv_requestMaterial(target: NvMaterialTargetType,
                            completion: @escaping (Result<(items: [NvMaterial], total: Int, hasMore: Bool), NvRequestError>) -> Void) {
        netOperator.requestMaterial(target: target) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let responseData):
                    // 检查本地文件， 设置本地文件路径
                    self.nv_fetchDownloadMaterialsState(materials: responseData.items) {
                        completion(result)
                    }
                case .failure:
                    completion(result)
                }
            }
        }
    }
    
    // 适用于同类型数组
    func nv_fetchDownloadMaterialsState(materials: [NvMaterial],
                                        completion: @escaping () -> Void) {
        // 批量查询下载状态
        let packageIdsAndVersions = materials.map { return (packageId: $0.packageId, version: $0.version) }
        database.batchGetDownloadedPathsAsync(items: packageIdsAndVersions) { downloadStatusMap in
            
            var dMaterial: [String] = []

            // 移除处理中的素材并获取数据
            self.processingQueue.sync(flags: .barrier) {
                dMaterial.append(contentsOf: self.processingMaterials.keys)
            }
            // 为已下载的素材设置路径信息
            for material in materials {
                if let dInfo = downloadStatusMap[material.packageId] {
                    material.packagePath = dInfo.packagePath
                    material.licPath = dInfo.licPath
                    material.downloadStatus = .finished
                } else if dMaterial.contains(material.packageId) {
                    // 下载中状态
                    material.downloadStatus = .downloading
                } else {
                    material.downloadStatus = .none
                }
            }
            completion()
        }
    }
    
    func processDownloadedMaterial(_ material: NvMaterial,
                                   fileAt downloadFile: URL) -> (packagePath: String,
                                                                 licPath: String)? {
        
        guard let packageExts = NvMaterial.materialFileExt(type: material.type.rawValue,
                                                           categorie: material.category,
                                                           kind: material.kind),
              let firstPackageExt = packageExts.first else {
            log.error("handle materialFileExt error:\(material.type.rawValue) -- \(material.category) -- \(material.kind)")
            return nil
        }
        
        let downloadMaterialDir = NSHomeDirectory() + materialDir
        let downloadCachePath = "\(downloadMaterialDir)cache/"
        
        let fm = FileManager.default
        if !fm.fileExists(atPath: downloadCachePath) {
            try? fm.createDirectory(atPath: downloadCachePath, withIntermediateDirectories: true)
        }
        var packagePath = ""
        var licPath = ""
        
        if !material.needUnzip {
            let dstFilePath = downloadMaterialDir + downloadFile.lastPathComponent
            do {
                try fm.moveItem(at: downloadFile, to: URL(fileURLWithPath: dstFilePath))
                packagePath = dstFilePath
            } catch {
                log.error("handle moveItem: \(error)")
            }
        } else {
            let zipFilePath = downloadCachePath + material.packageId + ".zip"
            try? fm.removeItem(atPath: zipFilePath)
            let zipFileURL = URL(fileURLWithPath: zipFilePath)
            
            let unzipTempDir = downloadCachePath + material.packageId
            do {
                try fm.moveItem(at: downloadFile, to: zipFileURL)
                try Zip.unzipFile(zipFileURL, destination: URL(fileURLWithPath: unzipTempDir), overwrite: true, password: nil)
                if firstPackageExt.isEmpty {
                    let dstDir = downloadMaterialDir + material.packageId
                    try? fm.removeItem(atPath: dstDir)
                    try fm.moveItem(atPath: unzipTempDir, toPath: dstDir)
                    packagePath = dstDir
                    licPath = ""
                } else {
                    let contents = try fm.contentsOfDirectory(atPath: unzipTempDir)
                    // 找到后缀在packageExts中的效果包和 后缀为lic的文件
                    var packageFile: String?
                    var licFileName: String?
                    for file in contents {
                        let lowercased = file.lowercased()
                        if packageExts.contains(where: { lowercased.hasSuffix($0.lowercased()) }) {
                            packageFile = file
                        } else if lowercased.hasSuffix(".lic") {
                            licFileName = file
                        }
                    }
                    guard let packageFile = packageFile, let licFileName = licFileName else {
                        log.error("handle package error:\(material.packageId)")
                        return nil
                    }
                    // 移动文件
                    let srcPackagePath = unzipTempDir + "/" + packageFile
                    let dstPackagePath = downloadMaterialDir + packageFile
                    try? fm.removeItem(atPath: dstPackagePath)
                    try fm.moveItem(atPath: srcPackagePath, toPath: dstPackagePath)
                    
                    let srcLicPath = unzipTempDir + "/" + licFileName
                    let dstLicPath = downloadMaterialDir + licFileName
                    try? fm.removeItem(atPath: dstLicPath)
                    try fm.moveItem(atPath: srcLicPath, toPath: dstLicPath)
                    
                    packagePath = dstPackagePath
                    licPath = dstLicPath
                    // 清理旧版本
                    if let downloadContents = try? fm.contentsOfDirectory(atPath: downloadMaterialDir) {
                        for file in contents {
                            if file.hasPrefix(material.packageId),
                               file != licFileName,
                               file != packageFile {
                                let fullPath = downloadMaterialDir + file
                                try? fm.removeItem(atPath: fullPath)
                            }
                        }
                    }
                }
            } catch let error {
                log.error("handle unzipFile: \(error)")
            }
        }
        return packagePath.isEmpty ? nil : (packagePath: packagePath,
                                            licPath: licPath)
    }
    
}
