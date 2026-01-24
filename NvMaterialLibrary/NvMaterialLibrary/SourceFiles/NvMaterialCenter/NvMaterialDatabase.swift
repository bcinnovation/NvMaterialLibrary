//
//  NvMaterialDatabase.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/7/21.
//

import Foundation
import SQLite3

public class NvMaterialDatabase {
    
    // SQLite constants
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    private let queue = DispatchQueue(label: "com.nv.materialdb.queue")
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    public init(dbPath: String) {
        self.dbPath = dbPath
        if openDatabase() {
            createTable()
        }
    }
    
    deinit {
        closeDatabase()
    }
    
    private func openDatabase() -> Bool {
        let ret = sqlite3_open(dbPath, &db)
        if ret != SQLITE_OK {
            log.error("Unable to open database at \(dbPath)")
        }
        return ret == SQLITE_OK
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    private func createTable() {
        guard let db = db else { return }
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS material_downloads (
                package_id TEXT PRIMARY KEY,
                type INTEGER NOT NULL,
                category INTEGER NOT NULL,
                kind INTEGER NOT NULL,
                version TEXT NOT NULL,
                display_name TEXT NOT NULL,
                cover_url TEXT NOT NULL,
                zip_url TEXT NOT NULL,
                package_path TEXT NOT NULL,
                lic_path TEXT NOT NULL,
                is_post_package INTEGER NOT NULL DEFAULT 0,
                download_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS font_family_mapping (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                package_id TEXT NOT NULL,
                family_name TEXT NOT NULL,
                UNIQUE(package_id, family_name)
            );
            
            CREATE INDEX IF NOT EXISTS idx_material_type ON material_downloads(type);
            CREATE INDEX IF NOT EXISTS idx_material_type_category ON material_downloads(type, category);
            CREATE INDEX IF NOT EXISTS idx_material_download_time ON material_downloads(download_time);
            CREATE INDEX IF NOT EXISTS idx_font_family_name ON font_family_mapping(family_name);
            CREATE INDEX IF NOT EXISTS idx_font_package_id ON font_family_mapping(package_id);
            """
        if sqlite3_exec(db, createTableSQL, nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            log.error("Error creating table: \(errmsg)")
        }
    }
    
    // MARK: - Public Methods
    
    /// 在串行队列中同步执行数据库操作
    /// - Parameter block: 数据库操作闭包
    /// - Returns: 返回闭包执行结果
    public func sync<T>(_ block: () -> T) -> T {
        return queue.sync {
            return block()
        }
    }
    
    /// 在串行队列中异步执行数据库操作（无返回值）
    /// - Parameter block: 数据库操作闭包
    public func async(_ block: @escaping () -> Void) {
        queue.async {
            block()
        }
    }
    
    public func insertMaterial(_ material: NvMaterial) -> Bool {
        let insertSQL = """
            INSERT OR REPLACE INTO material_downloads 
            (package_id, type, category, kind, version, display_name, cover_url, zip_url, package_path, lic_path, is_post_package)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        sqlite3_bind_text(statement, 1, material.packageId.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(material.type.rawValue))
        sqlite3_bind_int(statement, 3, Int32(material.category))
        sqlite3_bind_int(statement, 4, Int32(material.kind))
        sqlite3_bind_text(statement, 5, material.version.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 6, material.displayName.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 7, material.coverUrl.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 8, material.zipUrl.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        
        let relativePackagePath = convertToRelativePath(material.packagePath)
        let relativeLicPath = convertToRelativePath(material.licPath)
        
        sqlite3_bind_text(statement, 9, relativePackagePath.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 10, relativeLicPath.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 11, material.isPostPackage ? 1 : 0)
        
        let result = sqlite3_step(statement) == SQLITE_DONE
        sqlite3_finalize(statement)
        
        return result
    }
    
    public func getMaterial(packageId: String) -> NvMaterial? {
        let querySQL = "SELECT * FROM material_downloads WHERE package_id = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK else {
            log.error("Error preparing query statement")
            return nil
        }
        
        sqlite3_bind_text(statement, 1, packageId.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        
        var material: NvMaterial?
        
        if sqlite3_step(statement) == SQLITE_ROW {
            material = createMaterialFromRow(statement!)
        }
        
        sqlite3_finalize(statement)
        return material
    }
    
    public func getMaterials(packageIds: [String]) -> [String: NvMaterial] {
        guard !packageIds.isEmpty else { return [:] }
        
        // 构造占位符 (?, ?, ?, ...)
        let placeholders = Array(repeating: "?", count: packageIds.count).joined(separator: ", ")
        let querySQL = "SELECT * FROM material_downloads WHERE package_id IN (\(placeholders))"
        
        var statement: OpaquePointer?
        var result: [String: NvMaterial] = [:]
        
        guard sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK else {
            log.error("Error preparing query statement")
            return result
        }
        
        // 绑定参数
        for (index, id) in packageIds.enumerated() {
            sqlite3_bind_text(statement, Int32(index + 1), id.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        }
        
        // 遍历结果
        while sqlite3_step(statement) == SQLITE_ROW {
            if let material = createMaterialFromRow(statement!) {
                result[material.packageId] = material
            }
        }
        
        sqlite3_finalize(statement)
        return result
    }
    
    public func isDownloaded(packageId: String) -> Bool {
        let querySQL = "SELECT 1 FROM material_downloads WHERE package_id = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        sqlite3_bind_text(statement, 1, packageId.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        
        let result = sqlite3_step(statement) == SQLITE_ROW
        sqlite3_finalize(statement)
        
        return result
    }
    
    public func getDownloadedMaterials(type: NvMaterialType? = nil) -> [NvMaterial] {
        var querySQL = "SELECT * FROM material_downloads"
        
        if let type = type {
            querySQL += " WHERE type = ?"
        }
        
        querySQL += " ORDER BY download_time DESC"
        
        var statement: OpaquePointer?
        var materials: [NvMaterial] = []
        
        guard sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK else {
            return materials
        }
        
        if let type = type {
            sqlite3_bind_int(statement, 1, Int32(type.rawValue))
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let material = createMaterialFromRow(statement!) {
                materials.append(material)
            }
        }
        
        sqlite3_finalize(statement)
        
        return materials
    }
    
    public func deleteMaterial(packageId: String) -> Bool {
        let deleteSQL = "DELETE FROM material_downloads WHERE package_id = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        sqlite3_bind_text(statement, 1, packageId.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        
        let result = sqlite3_step(statement) == SQLITE_DONE
        sqlite3_finalize(statement)
        
        return result
    }
    
    public func updatePaths(packageId: String, packagePath: String, licPath: String) -> Bool {
        let updateSQL = "UPDATE material_downloads SET package_path = ?, lic_path = ? WHERE package_id = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        sqlite3_bind_text(statement, 1, convertToRelativePath(packagePath).cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, convertToRelativePath(licPath).cString(using: .utf8), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, packageId.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        
        let result = sqlite3_step(statement) == SQLITE_DONE
        sqlite3_finalize(statement)
        
        return result
    }
    
    // MARK: - Private Helper Methods
    
    private func createMaterialFromRow(_ statement: OpaquePointer) -> NvMaterial? {
        let material = NvMaterial()
        
        if let packageIdC = sqlite3_column_text(statement, 0) {
            material.packageId = String(cString: packageIdC)
        }
        
        material.type = NvMaterialType(rawValue: Int(sqlite3_column_int(statement, 1))) ?? .undefined
        material.category = Int(sqlite3_column_int(statement, 2))
        material.kind = Int(sqlite3_column_int(statement, 3))
        if let versionC = sqlite3_column_text(statement, 4) {
            material.version = String(cString: versionC)
        }
        
        if let displayNameC = sqlite3_column_text(statement, 5) {
            material.displayName = String(cString: displayNameC)
        }
        
        if let coverUrlC = sqlite3_column_text(statement, 6) {
            material.coverUrl = String(cString: coverUrlC)
        }
        
        if let zipUrlC = sqlite3_column_text(statement, 7) {
            material.zipUrl = String(cString: zipUrlC)
        }
        
        if let packagePathC = sqlite3_column_text(statement, 8) {
            let relativePath = String(cString: packagePathC)
            // 转换为绝对路径
            material.packagePath = convertToAbsolutePath(relativePath)
        }
        
        if let licPathC = sqlite3_column_text(statement, 9) {
            let relativePath = String(cString: licPathC)
            // 转换为绝对路径
            material.licPath = convertToAbsolutePath(relativePath)
        }
        
        let isPostPackageValue = sqlite3_column_int(statement, 10) // 注意列索引
        material.isPostPackage = (isPostPackageValue == 1)
        
        material.downloadStatus = .finished
        return material
    }
}

// MARK: - Convenience Methods

extension NvMaterialDatabase {
    
    public func recordDownload(material: NvMaterial,
                               packagePath: String,
                               licPath: String,
                               completion: @escaping (Bool) -> Void) {
        
        material.packagePath = packagePath
        material.licPath = licPath
        queue.async {
            let ret = self.insertMaterial(material)
            DispatchQueue.main.async {
                completion(ret)
            }
        }
    }
    
    public func batchGetDownloadedPathsAsync(
        items: [(packageId: String, version: String)],
        completion: @escaping ([String: (packagePath: String, licPath: String)]) -> Void
    ) {
        queue.async {
            var result: [String: (packagePath: String, licPath: String)] = [:]
            guard !items.isEmpty else {
                DispatchQueue.main.async {
                    completion(result)
                }
                return
            }

            let placeholders = Array(repeating: "?", count: items.count).joined(separator: ",")
            let querySQL = "SELECT package_id, version, package_path, lic_path FROM material_downloads WHERE package_id IN (\(placeholders))"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, querySQL, -1, &statement, nil) == SQLITE_OK {
                // 绑定 packageId
                for (index, item) in items.enumerated() {
                    sqlite3_bind_text(statement, Int32(index + 1), item.packageId.cString(using: .utf8), -1, self.SQLITE_TRANSIENT)
                }

                while sqlite3_step(statement) == SQLITE_ROW {
                    if let packageIdC = sqlite3_column_text(statement, 0),
                       let versionC = sqlite3_column_text(statement, 1),
                       let packagePathC = sqlite3_column_text(statement, 2),
                       let licPathC = sqlite3_column_text(statement, 3) {

                        let packageId = String(cString: packageIdC)
                        let dbVersion = String(cString: versionC)
                        let relativePackagePath = String(cString: packagePathC)
                        let relativeLicPath = String(cString: licPathC)

                        // 只保留 version 一致的
                        if let target = items.first(where: { $0.packageId == packageId }) {
                            if target.version == dbVersion {
                                let absPackagePath = self.convertToAbsolutePath(relativePackagePath)
                                let absLicPath = self.convertToAbsolutePath(relativeLicPath)
                                result[packageId] = (packagePath: absPackagePath, licPath: absLicPath)
                            }
                        }
                    }
                }
            }
            sqlite3_finalize(statement)

            // 回到主线程
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // MARK: - Path Conversion Helpers
    
    private func convertToRelativePath(_ absolutePath: String) -> String {
        guard !absolutePath.isEmpty else { return absolutePath }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        // 如果路径以Documents开头，提取相对路径
        if absolutePath.hasPrefix(documentsPath) {
            let relativePath = String(absolutePath.dropFirst(documentsPath.count))
            return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        }
        
        // 如果路径以NSHomeDirectory开头，提取相对路径
        let homePath = NSHomeDirectory()
        if absolutePath.hasPrefix(homePath) {
            let relativePath = String(absolutePath.dropFirst(homePath.count))
            return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        }
        
        // 已经是相对路径或其他情况，直接返回
        return absolutePath
    }
    
    private func convertToAbsolutePath(_ relativePath: String) -> String {
        guard !relativePath.isEmpty else { return relativePath }
        
        // 如果已经是绝对路径，直接返回
        if relativePath.hasPrefix("/") {
            return relativePath
        }
        
        // 转换为绝对路径
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return documentsPath + "/" + relativePath
    }
}

// MARK: - Font Management

extension NvMaterialDatabase {
    
    /// 保存字体包的family name映射
    /// @param packageId 字体包ID
    /// @param familyNames 字体family name数组
    /// @return 是否保存成功
    public func saveFontFamilyMapping(packageId: String, familyNames: [String]) -> Bool {
        // 先删除已存在的映射
        _ = deleteFontFamilyMapping(packageId: packageId)
        
        let insertSQL = "INSERT INTO font_family_mapping (package_id, family_name) VALUES (?, ?)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            log.error("Error preparing font family insert statement")
            return false
        }
        
        var allSuccess = true
        
        for familyName in familyNames {
            sqlite3_bind_text(statement, 1, packageId.cString(using: .utf8), -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, familyName.cString(using: .utf8), -1, SQLITE_TRANSIENT)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                allSuccess = false
                log.error("Error inserting font family mapping: \(packageId) - \(familyName)")
            }
            
            sqlite3_reset(statement)
        }
        
        sqlite3_finalize(statement)
        return allSuccess
    }
    
    /// 根据family name查询字体包信息
    /// @param familyName 字体family name
    /// @return 字体包信息，如果未找到返回nil
    public func getFontPackage(byFamilyName familyName: String) -> NvMaterial? {
        let querySQL = """
            SELECT md.* FROM material_downloads md
            INNER JOIN font_family_mapping ffm ON md.package_id = ffm.package_id
            WHERE ffm.family_name = ? AND md.type = ?
            """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK else {
            log.error("Error preparing font package query statement")
            return nil
        }
        
        sqlite3_bind_text(statement, 1, familyName, -1, nil)
        sqlite3_bind_int(statement, 2, Int32(NvMaterialType.font.rawValue))
        
        var material: NvMaterial?
        
        if sqlite3_step(statement) == SQLITE_ROW {
            material = createMaterialFromRow(statement!)
        }
        
        sqlite3_finalize(statement)
        return material
    }
    
    /// 获取字体包的所有family names
    /// @param packageId 字体包ID
    /// @return family name数组
    public func getFontFamilyNames(packageId: String) -> [String] {
        let querySQL = "SELECT family_name FROM font_family_mapping WHERE package_id = ?"
        var statement: OpaquePointer?
        var familyNames: [String] = []
        
        guard sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK else {
            log.error("Error preparing font family names query statement")
            return familyNames
        }
        
        sqlite3_bind_text(statement, 1, packageId.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let familyNameC = sqlite3_column_text(statement, 0) {
                familyNames.append(String(cString: familyNameC))
            }
        }
        
        sqlite3_finalize(statement)
        return familyNames
    }
    
    /// 删除字体包的family name映射
    /// @param packageId 字体包ID
    /// @return 是否删除成功
    public func deleteFontFamilyMapping(packageId: String) -> Bool {
        let deleteSQL = "DELETE FROM font_family_mapping WHERE package_id = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        sqlite3_bind_text(statement, 1, packageId.cString(using: .utf8), -1, SQLITE_TRANSIENT)
        
        let result = sqlite3_step(statement) == SQLITE_DONE
        sqlite3_finalize(statement)
        
        return result
    }
    
    /// 检查family name是否已存在
    /// @param familyName 字体family name
    /// @return 是否存在
    public func isFontFamilyExists(familyName: String) -> Bool {
        let querySQL = "SELECT 1 FROM font_family_mapping WHERE family_name = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        sqlite3_bind_text(statement, 1, familyName, -1, nil)
        
        let result = sqlite3_step(statement) == SQLITE_ROW
        sqlite3_finalize(statement)
        
        return result
    }
}
