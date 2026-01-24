//
//  NvNetTargetType.swift
//  NvMaterialLibrary
//
//  Created by meishe on 2025/9/12.
//

import Foundation

public enum NvRequestError: Error, Equatable {
    case logError                       // 没有登录 / Not logged in
    case rspError(error: Error?)        // 返回失败信息 / Response error
    case netError(error: Error?)        // 接口失败，包含系统 Error / Network error with system error
    
    public static func == (lhs: NvRequestError, rhs: NvRequestError) -> Bool {
        switch (lhs, rhs) {
        case (.logError, .logError):
            return true
        case (.rspError, .rspError):
            return true   // 只要都是 rspError 就算相等，不比较 error 里的内容
        case (.netError, .netError):
            return true   // 同上
        default:
            return false
        }
    }
}

public enum NvHttpMethod: String {
    case get = "GET"
    case post = "POST"
    case upload = "UPLOAD"
}

public protocol NvNetTargetType {
    // 请求参数 / Request parameters
    // bodyParameters 如果 value 是自定义对象（比如你自己写的类/struct），直接放进去会报错。你需要先把对象转换成字典或其他 JSON 支持的类型，比如用 Codable 转换成 [String: Any]。
    var paramInfo: (urlParameters: [String: Any]?, bodyParameters: Any?) { get }
    
    // 请求地址 / Request URL
    var url: String { get }
    
    // 请求方法（GET/POST 等） / HTTP method (GET, POST, etc.)
    var method: NvHttpMethod { get }
    
    // 请求头 / HTTP headers
    var headers: [String: String]? { get }
    
    func encoding(bodyParameters: Any) -> Data?
    // 请求成功的code
    var normalCode: Int { get }
    
    var responseType: Decodable.Type { get }
}

public protocol NvCancellable {
    func cancel()
}

extension URLSessionDataTask: NvCancellable {}

extension JSONSerialization {
    /// 安全转换任意对象为 JSON Data
    /// - Parameters:
    ///   - object: 需要转换的对象
    ///   - options: JSONSerialization.WritingOptions
    /// - Returns: 如果是合法 JSON 对象则返回 Data，否则返回 nil
    static public func safeData(
        withJSONObject object: Any,
        options: JSONSerialization.WritingOptions = []
    ) -> Data? {
        guard JSONSerialization.isValidJSONObject(object) else {
            log.error("Invalid JSON object:", object)
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [])
            return data
        } catch {
            print("JSONSerialization failed:", error)
            return nil
        }
    }
}

// async
public extension NvNetTargetType {
    
    public func encoding(bodyParameters: Any) -> Data? {
        let jsonData = JSONSerialization.safeData(
            withJSONObject: bodyParameters,
            options: [.sortedKeys]
        )
        return jsonData
    }
    
    public func makeURLRequest() -> URLRequest? {
        guard let url = URL(string: self.url) else { return nil }
        var request = URLRequest(url: url)
        if method == .upload {
            request.httpMethod = "POST"
        } else {
            request.httpMethod = self.method.rawValue
        }
        if let headers = self.headers {
            headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        }
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let pInfo = paramInfo
        if let urlParameters = pInfo.urlParameters, !urlParameters.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = urlParameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            if let newUrl = components?.url { request.url = newUrl }
        }
        
        if method != .upload, let bodyParameters = pInfo.bodyParameters {
            request.httpBody = encoding(bodyParameters: bodyParameters)
        }
        return request
    }
    
    // 泛型请求方法
    func request(completion: @escaping (Result<Data, NvRequestError>) -> Void
    ) -> NvCancellable? {
        let target = self
        guard let request = makeURLRequest() else {
            completion(.failure(.netError(error: nil)))
            return nil
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.netError(error: error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.rspError(error: nil)))
                return
            }
            completion(.success(data))
        }
        task.resume()
        return task
    }
    
}

// sync
public extension NvNetTargetType {
    
//    func requestSync<T>(parse: @escaping (Data) -> Result<T, NvRequestError>) async -> Result<T, NvRequestError> {
//        guard let request = makeURLRequest() else {
//            return .failure(.netError(error: nil))
//        }
//        do {
//            let (data, _) = try await URLSession.shared.data(for: request)
//            return parse(data)
//        } catch {
//            return .failure(.netError(error: error))
//        }
//    }
    
    public func requestSyncWithSemaphore() -> Result<Data, NvRequestError> {
        guard let request = makeURLRequest() else {
            return .failure(.netError(error: nil))
        }
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Data, NvRequestError>!
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                result = .failure(.netError(error: error))
                return
            }
            
            guard let data = data else {
                result = .failure(.rspError(error: nil))
                return
            }
            
            result = .success(data)
        }
        
        task.resume()
        semaphore.wait() // 阻塞当前线程，等待网络返回
        return result
    }
}

public struct NvResponse<T: Decodable>: NvCodable {
    public let code: Int
    public let msg: String
    public let data: T?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case msg
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        code = try container.decode(Int.self, forKey: .code)

        // 优先解析 message，没有就解析 msg
        if let msg = try? container.decode(String.self, forKey: .message) {
            self.msg = msg
        } else {
            msg = (try? container.decode(String.self, forKey: .msg)) ?? ""
        }
        if let value = try? container.decodeIfPresent(T.self, forKey: .data) {
            data = value
        } else {
            data = nil
        }
    }
    
    public func encode(to encoder: any Encoder) throws {}
}


