//
//  NvMultipartUploadStream.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/15.
//

import Foundation
import Foundation
import UniformTypeIdentifiers
import MobileCoreServices // iOS 13 及以下使用

public class NvMultipartUploadStream: InputStream {
    private let boundary: String
    private let parameters: [String: String]
    private let files: [(field: String, url: URL, fileName: String, mimeType: String)]
    
    private var streamQueue: [InputStream] = []
    private var currentStream: InputStream?
    
    init(boundary: String = "Boundary-\(UUID().uuidString)",
         parameters: [String: String] = [:],
         files: [(field: String, url: URL, fileName: String, mimeType: String)]) {
        
        self.boundary = boundary
        self.parameters = parameters
        self.files = files
        super.init(data: Data()) // 父类必须 init，但我们不用
        buildStreamQueue()
    }
    
    private func buildStreamQueue() {
        var streams: [InputStream] = []
        
        // 文本参数部分
        for (key, value) in parameters {
            let header = "--\(boundary)\r\n"
            + "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
            + "\(value)\r\n"
            streams.append(InputStream(data: Data(header.utf8)))
        }
        
        // 文件部分
        for file in files {
            let header = "--\(boundary)\r\n"
            + "Content-Disposition: form-data; name=\"\(file.field)\"; filename=\"\(file.fileName)\"\r\n"
            + "Content-Type: \(file.mimeType)\r\n\r\n"
            streams.append(InputStream(data: Data(header.utf8)))
            
            // 🔥 文件流（不会加载进内存）
            if let fileStream = InputStream(url: file.url) {
                streams.append(fileStream)
            }
            streams.append(InputStream(data: Data("\r\n".utf8)))
        }
        
        // 结束标识
        let footer = "--\(boundary)--\r\n"
        streams.append(InputStream(data: Data(footer.utf8)))
//        printStreams(streams)
        streamQueue = streams
        currentStream = streamQueue.first
    }
    private func printStreams(_ streams: [InputStream]) {
        let data = NSMutableData()
        for stream in streams {
            stream.open()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let bytesRead = stream.read(&buffer, maxLength: buffer.count)
                if bytesRead > 0 {
                    data.append(buffer, length: bytesRead)
                }
            }
            stream.close()
        }

        // 安全打印
        let previewData = Data(data.prefix(2048)) // ✅ 转成 Data
        if let previewString = String(data: previewData, encoding: .utf8) {
            print(previewString)
        } else {
            print("Multipart contains binary data; preview skipped")
        }

        // 或者打印头部和参数而不打印文件内容
        for param in parameters {
            print("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(param.key)\"\r\n\r\n\(param.value)")
        }
        for file in files {
            print("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(file.field)\"; filename=\"\(file.fileName)\"\r\nContent-Type: \(file.mimeType)\r\n[Binary Data]")
        }
        print("--\(boundary)--")
    }
    // MARK: - InputStream override
    
    public override func open() {
        currentStream?.open()
    }
    
    public override func close() {
        currentStream?.close()
    }
    
    public override var hasBytesAvailable: Bool {
        let ret = currentStream != nil
        if !ret {
            log.error("hasBytesAvailable error")
        }
        return ret
    }
    
    public override var streamStatus: Stream.Status {
        if currentStream == nil {
            log.info("streamStatus: closed (all streams consumed)")
            return .closed   // 所有都读完才算 closed
        }
        // 如果当前流 atEnd 但还有下一个，就别提前返回 .atEnd
        if currentStream?.streamStatus == .atEnd, streamQueue.count > 1 {
            return .open
        }
        let status = currentStream?.streamStatus ?? .notOpen
        return status
    }

    public override var streamError: Error? {
        let error = currentStream?.streamError
        return error
    }

    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        for s in streamQueue {
            s.schedule(in: aRunLoop, forMode: mode)
        }
    }

    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        for s in streamQueue {
            s.remove(from: aRunLoop, forMode: mode)
        }
    }
    
    public override var delegate: StreamDelegate? {
        get {
            return currentStream?.delegate
        }
        set {
            currentStream?.delegate = newValue
        }
    }
    
    public override func property(forKey key: Stream.PropertyKey) -> Any? {
        return currentStream?.property(forKey: key)
    }

    public override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
        return currentStream?.setProperty(property, forKey: key) ?? false
    }
    
    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        while let stream = currentStream {
            let bytesRead = stream.read(buffer, maxLength: len)
            if bytesRead > 0 {
                // 每次读到数据都打印（可注释掉大文件时）
//                log.info("Read \(bytesRead) bytes from stream \(stream)，\(len)")
                return bytesRead
            } else {
                let sDelegate = stream.delegate
                stream.close()
                if !streamQueue.isEmpty { streamQueue.removeFirst() }
                currentStream = streamQueue.first
                currentStream?.delegate = sDelegate
                currentStream?.open()
            }
        }
        return 0
    }
    
    /// 根据文件路径返回 MIME 类型
    public static func mimeType(forPath path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        return mimeType(forPathExtension: ext)
    }

    /// 根据文件扩展名返回 MIME 类型
    private static func mimeType(forPathExtension pathExtension: String) -> String {
        if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, visionOS 1, *) {
            // iOS 14+ 使用 UTType
            return UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        } else {
            // 旧版本使用 MobileCoreServices
            if let id = UTTypeCreatePreferredIdentifierForTag(
                    kUTTagClassFilenameExtension,
                    pathExtension as CFString,
                    nil
                )?.takeRetainedValue(),
                let contentType = UTTypeCopyPreferredTagWithClass(
                    id,
                    kUTTagClassMIMEType
                )?.takeRetainedValue() {
                return contentType as String
            }
            return "application/octet-stream"
        }
    }
}
