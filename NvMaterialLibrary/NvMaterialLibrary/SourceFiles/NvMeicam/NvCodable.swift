//
//  Codable.swift
//  NvMeicam
//
//  Created by meishe on 2024/6/7.
//

import UIKit

public protocol NvCodable: Codable {}

extension NvCodable {
    
    public func deepCopy() -> Self? {
        Self.deepCopy(self)
    }
    
    public static func deepCopy(_ object: Self) -> Self? {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(object)
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: data)
        } catch {
            log.error("Failed to deep copy: \(error)")
            return nil
        }
    }
    
    public func toData() -> Data? {
        do {
            let encoder = JSONEncoder()
            return try encoder.encode(self)
        } catch {
            log.error("Failed to convert to data: \(error)")
            return nil
        }
    }
    
    public func toJSON() -> [String: Any]? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        } catch {
            log.error("Failed to convert to dictionary: \(error)")
            return nil
        }
    }
    
    public func toJSONString() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            log.error("Failed to convert to JSON string: \(error)")
            return nil
        }
    }
}

extension Decodable {
    
    public static func deserialize(from data: Data?) -> Self? {
        guard let data = data else { return nil }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: data)
        } catch {
            log.error("Failed to deserialize from data: \(error)")
            return nil
        }
    }
    
    public static func deserialize(from dict: [String: Any]?) -> Self? {
        guard let dict = dict else { return nil }
        do {
            guard JSONSerialization.isValidJSONObject(dict) else {
                log.error("Invalid JSON object:", dict)
                return nil
            }
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: data)
        } catch {
            log.error("Failed to deserialize from dictionary: \(error)")
            return nil
        }
    }
    
    public static func deserialize(from json: String?) -> Self? {
        guard let json = json, let data = json.data(using: .utf8) else { return nil }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: data)
        } catch {
            log.error("Failed to deserialize from JSON string: \(error)")
            return nil
        }
    }
}

public struct AnyDecodable: Decodable {
    public let value: Any

    public init(from decoder: Decoder) throws {
        if let intValue = try? decoder.singleValueContainer().decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? decoder.singleValueContainer().decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            value = stringValue
        } else if let boolValue = try? decoder.singleValueContainer().decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? decoder.singleValueContainer().decode([AnyDecodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? decoder.singleValueContainer().decode([String: AnyDecodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            value = NSNull()
            debugPrint("Decoder Unsupported Type")
        }
    }
}

public enum NvCodableJSON {
    public static func modelToMap<T: NvCodable>(model: T) -> [String: Any]? { model.toJSON() }
    public static func mapToModel<T: Decodable>(map: [String: Any], modelType: T.Type) -> T? {
        guard !map.isEmpty else { return nil }
        return modelType.deserialize(from: map)
    }

    public static func modelToJson<T: NvCodable>(model: T) -> String? { model.toJSONString() }
    public static func jsonToModel<T: Decodable>(jsonString: String, modelType: T.Type) -> T? {
        guard !jsonString.isEmpty else { return nil }
        return modelType.deserialize(from: jsonString)
    }

    public static func modelToData<T: NvCodable>(model: T) -> Data? {
        return model.toData()
    }

    public static func dataToModel<T: Decodable>(data: Data?, modelType: T.Type) -> T? {
        guard let inputData = data else { return nil }
        return T.deserialize(from: inputData)
    }

    public static func dataToArrayModel<T: Decodable>(data: Data?, modelType: T.Type) -> [T] {
        var modelArray: [T] = []
        if let jsonData = data {
            do {
                let obj = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions())
                if let array = obj as? [[String: Any]] {
                    array.forEach {
                        if let map: T = mapToModel(map: $0, modelType: modelType) {
                            modelArray.append(map)
                        }
                    }
                } else if let dicObj = obj as? [String: Any] {
                    if let map: T = mapToModel(map: dicObj, modelType: modelType) {
                        modelArray.append(map)
                    }
                }
                return modelArray
            } catch {
                log.error("data转模型:" + error.localizedDescription)
                return modelArray
            }
        } else {
            return modelArray
        }
    }

    public static func jsonArrayToModel<T: NvCodable>(jsonString: String, modelType: T.Type) -> [T] {
        guard !jsonString.isEmpty else { return [] }
        var modelArray: [T] = []
        guard let data = jsonString.data(using: .utf8) else { return [] }
        do {
            let array = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String: Any]]
            array?.forEach {
                if let map: T = mapToModel(map: $0, modelType: modelType) {
                    modelArray.append(map)
                }
            }
            return modelArray
        } catch {
            log.error("JSON转模型:" + error.localizedDescription)
            return modelArray
        }
    }

    public static func modelArrayToJson<T: NvCodable>(array: [T]) -> String {
        var dicts: [[String: Any]] = []
        for index in 0 ..< array.count {
            let item = array[index]
            if let dict = item.toJSON() {
                dicts.append(dict)
            }
        }
        if !JSONSerialization.isValidJSONObject(dicts) {
            log.error("模型转JSON: a given object can be converted to JSON data.")
            return ""
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: dicts, options: [])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            log.error("模型转JSON:" + error.localizedDescription)
            return ""
        }
    }

    public static func dictArrayToModel<T: NvCodable>(array: [[String: Any]], modelType: T.Type) -> [T] {
        if array.isEmpty { return [] }
        var modelArray: [T] = []
        array.forEach {
            if let map: T = mapToModel(map: $0, modelType: modelType) {
                modelArray.append(map)
            }
        }
        return modelArray
    }
    public static func jsonToDictArray(jsonString: String) -> [[String: Any]] {
        guard let jsonData = jsonString.data(using: .utf8) else { return [] }
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
            return jsonArray as? [[String: Any]] ?? []
        } catch {
            return []
        }
        return []
    }
    public static func dictArrayToJson(dicts: [[String: Any]]) -> String {
        if !JSONSerialization.isValidJSONObject(dicts) { return "" }
        do {
            let data = try JSONSerialization.data(withJSONObject: dicts, options: [])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
