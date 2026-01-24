//
//  NvVideoEditTabItem.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/3.
//

import Foundation

open class NvVideoEditTabItem: NvTabBarCategory {
    public var displayName: String
    public var listParam: NvMaterialListParam
    
    public init(displayName: String, listParam: NvMaterialListParam) {
        self.displayName = displayName
        self.listParam = listParam
    }
    
    public var itemIndicate: String {
        "\(listParam.type)-\(listParam.categoryId ?? 0)-\(listParam.kindId ?? 0)-\(displayName)"
    }
}

open class NvVideoEditResponseTabItem: Codable {
    public var superId: Int = 0
    public var id: Int = 0
    public var displayName: String = ""
    public var items: [NvVideoEditResponseTabItem] = []
    
    public required init() {}
    
    enum CodingKeys: String, CodingKey {
        case id, displayName, categories, kinds
    }
    
    public func parseTabs(categoryId: Int? = nil, forEditModule: Bool = true) -> [NvVideoEditTabItem] {
        guard let type = NvMaterialType(rawValue: id) else {
            log.error("NvVideoEditResponseTabItem error:\(displayName) - \(id)")
            return []
        }
        var retArray = [NvVideoEditTabItem]()
        if !items.isEmpty {
            if forEditModule {
                if let categoryId = categoryId,
                   categoryId != 0 {
                    if let categoryItem = items.first(where: { tabItem in
                        return tabItem.id == categoryId
                    }) {
                        for kindItem in categoryItem.items {
                            retArray.append(NvVideoEditResponseTabItem.makeListParam(item: kindItem,
                                                                                     type: type,
                                                                                     categoryId: categoryId))
                        }
                    } else {
                        log.error("NvVideoEditResponseTabItem categoryId error:\(displayName) - \(categoryId)")
                    }
                } else {
                    for category in items {
                        retArray.append(NvVideoEditResponseTabItem.makeListParam(item: category,
                                                                                 type: type))
                    }
                }
            } else {
                for categoryItem in items {
                    for kindItem in categoryItem.items {
                        retArray.append(NvVideoEditResponseTabItem.makeListParam(item: kindItem,
                                                                                 type: type,
                                                                                 categoryId: categoryItem.id))
                    }
                }
            }
        } else {
            let param = NvMaterialListParam(type: type)
            retArray.append(NvVideoEditTabItem(displayName: displayName, listParam: param))
        }
        return retArray
    }
    
    public static func makeListParam(item: NvVideoEditResponseTabItem,
                                     type: NvMaterialType,
                                     categoryId: Int? = nil) -> NvVideoEditTabItem {
        if let categoryId = categoryId {
            let param = NvMaterialListParam(type: type, categoryId: categoryId, kindId: item.id)
            return NvVideoEditTabItem(displayName: item.displayName, listParam: param)
        } else {
            let param = NvMaterialListParam(type: type, categoryId: item.id)
            return NvVideoEditTabItem(displayName: item.displayName, listParam: param)
        }
    }
    
    // Custom initializer for decoding
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decodeIfPresent(Int.self, forKey: .id) {
            id = value
        } else if let value = try? container.decodeIfPresent(String.self, forKey: .id) {
            id = Int(Double(value) ?? 0)
        }
        displayName = (try? container.decodeIfPresent(String.self, forKey: .displayName)) ?? ""
        if let value = try? container.decodeIfPresent([NvVideoEditResponseTabItem].self, forKey: .categories) {
            items = value
        } else if let value = try? container.decodeIfPresent([NvVideoEditResponseTabItem].self, forKey: .kinds) {
            items = value
        }
        items.forEach { item in
            item.superId = id
        }
    }
    
    public func encode(to encoder: any Encoder) throws {}
}

open class NvVideoEditCategoryResponse: NvCodable {
    public var code: Int = 0
    public var data: [NvVideoEditResponseTabItem] = []
    public var msg: String = ""
    public required init() {}
    
    enum CodingKeys: String, CodingKey {
        case code, msg, data, message
    }
    
    // Custom initializer for decoding
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decodeIfPresent(Int.self, forKey: .code) {
            code = value
        } else if let value = try? container.decodeIfPresent(String.self, forKey: .code) {
            code = Int(Double(value) ?? 0)
        }
        if let value = try? container.decodeIfPresent(String.self, forKey: .msg) {
            msg = value
        } else if let value = try? container.decodeIfPresent(String.self, forKey: .message) {
            msg = value
        }
        if let value = try? container.decodeIfPresent([NvVideoEditResponseTabItem].self, forKey: .data) {
            data = value
        }
    }
    
    public func encode(to encoder: any Encoder) throws {}
}

public struct NvMaterialListResponse<T: NvMaterial>: NvCodable {
    public var elements: [T] = []
    public var total: Int = 0
    
    private enum CodingKeys: String, CodingKey {
        case elements, total
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decodeIfPresent([T].self, forKey: .elements) {
            elements = value
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: .total) {
            total = value
        } else if let value = try? container.decodeIfPresent(String.self, forKey: .total) {
            total = Int(Double(value) ?? 0)
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        //
    }
}
