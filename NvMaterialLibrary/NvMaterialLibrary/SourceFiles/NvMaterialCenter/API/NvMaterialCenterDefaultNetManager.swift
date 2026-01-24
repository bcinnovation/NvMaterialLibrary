//
//  NvMaterialCenterDefaultNetManager.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/2.
//

import Foundation

public class NvMaterialCenterDefaultNetManager: NvMaterialCenterNetManager {
    
    public func requestCategory(
        target: NvMaterialTargetType,
        completion: @escaping (Result<[NvTabBarCategory], NvRequestError>) -> Void
    ) {
        _ = target.request { result in
            switch result {
            case .success(let data):
                completion(target.parseTabResponse(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func requestMaterial(
        target: NvMaterialTargetType,
        completion: @escaping (Result<(items: [NvMaterial], total: Int, hasMore: Bool),
                               NvRequestError>) -> Void) {
        _ = target.request { result in
            switch result {
            case .success(let data):
                completion(target.parseMaterialListResponse(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func download(material: NvMaterial,
                         progress: @escaping (Double) -> Void,
                         completion: @escaping (Result<URL, NvRequestError>) -> Void) -> NvCancellable? {
        guard let url = URL(string: material.zipUrl) else {
            completion(.failure(.netError(error: NSError(domain: "Invalid zipUrl", code: -1))))
            return nil
        }
        return NvMaterialCenter.shared().transferManager.download(from: url,
                                                           progress: progress) { result in
            switch result {
            case .success(let tempURL):
                completion(.success(tempURL))
            case .failure(let error):
                completion(.failure(.netError(error: error)))
            }
        }
    }
    
}
