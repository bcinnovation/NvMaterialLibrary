//
//  NvTransferManager.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/12.
//

import Foundation

// MARK: - 公共类型
public enum NvTransferTaskType {
    case download
    case upload
}

public enum NvTransferTaskState {
    case idle
    case running
    case paused
    case completed
    case failed
}

public protocol NvTransferTask: NvCancellable, AnyObject {
    var id: UUID { get }
    var type: NvTransferTaskType { get }
    var state: NvTransferTaskState { get }
    func start()
    func pause()
    var onFinish: ((UUID) -> Void)? { get set }
}

// MARK: - 传输管理器
public class NvTransferManager {
    private var tasks: [UUID: NvTransferTask] = [:]
    
    public func addTask(_ task: NvTransferTask) {
        tasks[task.id] = task
        task.onFinish = { [weak self] id in
            self?.tasks.removeValue(forKey: id)
        }
        task.start()
    }
    
    public func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    public func getTask(by id: UUID) -> NvTransferTask? {
        return tasks[id]
    }
    
    @discardableResult
    public func download(from url: URL,
                         progress: ((Double) -> Void)? = nil,
                         completion: @escaping (Result<URL, Error>) -> Void) -> NvCancellable {
        let downloadTask = NvDownloadTask(url: url)
        downloadTask.progressHandler = progress
        downloadTask.completionHandler = completion
        addTask(downloadTask)
        return downloadTask
    }
    
    @discardableResult
    public func upload(url: URL,
                       urlParameters: [String: Any]? = nil,
                       bodyParameters: [String: String]? = nil,
                       files: [(field: String, url: URL, fileName: String, mimeType: String)],
                       headers: [String: String]? = nil,
                       progress: ((Double) -> Void)? = nil,
                       completion: ((Result<Data, Error>) -> Void)? = nil) -> NvCancellable? {
        let uploadTask = NvUploadTask.create(url: url,
                                             urlParameters: urlParameters,
                                             bodyParameters: bodyParameters,
                                             files: files,
                                             headers: headers,
                                             progress: progress,
                                             completion: completion)
        if let uploadTask = uploadTask {
            addTask(uploadTask)
            return uploadTask
        } else {
            let err = NSError(domain: "NvUploadTask",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "NvUploadTask create nil"])
            completion?(.failure(err))
        }
        return nil
    }
}

// MARK: - 下载任务
private class NvDownloadTask: NSObject, NvTransferTask, URLSessionDownloadDelegate {
    
    
    let id = UUID()
    let type: NvTransferTaskType = .download
    private(set) var state: NvTransferTaskState = .idle
    
    var progressHandler: ((Double) -> Void)?
    var completionHandler: ((Result<URL, Error>) -> Void)?
    
    var onFinish: ((UUID) -> Void)?
    
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession!
    private let url: URL
    
    init(url: URL) {
        self.url = url
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func start() {
        state = .running
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func pause() {
        state = .paused
        downloadTask?.cancel(byProducingResumeData: { _ in })
    }
    
    func cancel() {
        state = .failed
        downloadTask?.cancel()
    }
    
    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressHandler?(progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documents.appendingPathComponent(downloadTask.response?.suggestedFilename ?? "file.dat")
        
        try? fileManager.removeItem(at: destinationURL)
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            state = .completed
            DispatchQueue.main.async {
                self.completionHandler?(.success(destinationURL))
                self.onFinish?(self.id)
            }
        } catch {
            state = .failed
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
                self.onFinish?(self.id)
            }
        }
    }
    
    // 处理下载失败
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            state = .failed
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
                self.onFinish?(self.id)
            }
        }
    }
}

// MARK: - 上传任务

public class NvUploadTask: NSObject, NvTransferTask, URLSessionTaskDelegate, URLSessionDataDelegate {
    public let id = UUID()
    public let type: NvTransferTaskType = .upload
    public private(set) var state: NvTransferTaskState = .idle

    private var task: URLSessionUploadTask?
    private var session: URLSession?
    private var receivedData = Data()
    
    private var progressHandler: ((Double) -> Void)?
    private var completionHandler: ((Result<Data, Error>) -> Void)?
    
    public var onFinish: ((UUID) -> Void)?

    private init(progress: ((Double) -> Void)?,
                 completion: ((Result<Data, Error>) -> Void)?) {
        self.progressHandler = progress
        self.completionHandler = completion
    }

    // MARK: - Factory Method
    public static func create(url: URL,
                              urlParameters: [String: Any]? = nil,
                              bodyParameters: [String: String]? = nil,
                              files: [(field: String, url: URL, fileName: String, mimeType: String)],
                              headers: [String: String]? = nil,
                              progress: ((Double) -> Void)? = nil,
                              completion: ((Result<Data, Error>) -> Void)? = nil) -> NvUploadTask? {

        // 检查文件是否存在
        for file in files {
            guard FileManager.default.fileExists(atPath: file.url.path) else {
                print("❌ 文件不存在: \(file.url.path)")
                return nil
            }
        }

        let uploader = NvUploadTask(progress: progress, completion: completion)

        // 拼接 URL 参数
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        if let urlParameters = urlParameters,
           !urlParameters.isEmpty {
            components.queryItems = urlParameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }

        guard let finalURL = components.url else { return nil }
        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"

        // boundary
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // headers
        if let headers = headers {
            headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // multipart 流
        let stream = NvMultipartUploadStream(boundary: boundary,
                                             parameters: bodyParameters ?? [:],
                                             files: files)
        request.httpBodyStream = stream

        // session
        let session = URLSession(configuration: .default, delegate: uploader, delegateQueue: nil)
        uploader.session = session
        uploader.task = session.uploadTask(withStreamedRequest: request)

        return uploader
    }

    // MARK: - NvTransferTask
    public func start() {
        guard let task = task, state == .idle || state == .paused else { return }
        task.resume()
        state = .running
    }

    public func pause() {
        guard let task = task, state == .running else { return }
        task.suspend()
        state = .paused
    }

    public func cancel() {
        task?.cancel()
        state = .completed
    }

    // MARK: - URLSession Delegate
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        progressHandler?(progress)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            state = .failed
            completionHandler?(.failure(error))
        } else {
            state = .completed
            completionHandler?(.success(receivedData))
        }
        self.onFinish?(self.id)
        receivedData.removeAll()
        cleanUp()
    }
    
    private func cleanUp() {
        task = nil
        session?.invalidateAndCancel()
        session = nil
        progressHandler = nil
        completionHandler = nil
        onFinish = nil
    }
}
