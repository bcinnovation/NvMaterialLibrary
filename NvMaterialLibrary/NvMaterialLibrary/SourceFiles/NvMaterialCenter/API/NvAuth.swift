//
//  NvAuth.swift
//  NvVideoEditorUIX
//
//  Created by meishe on 2025/5/6.
//

import Foundation
import CryptoKit

open class NvAuth {
    static func getCanonicalQueryString(params: [String: String]) -> String {
        return params.sorted { $0.key < $1.key }
            .map { key, value in
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(key)=\(encodedValue)"
            }
            .joined(separator: "&")
    }

    static func sha256Hex(_ input: Data) -> String {
        let digest = SHA256.hash(data: input)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func hmac256(key: Data, message: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: message, using: symmetricKey)
        return Data(signature)
    }

    static func generateSign(secretKey: String, timestamp: String, nonce: String, canonicalRequestHex: String) -> String {
        let keyDate = hmac256(key: Data("MS\(secretKey)".utf8), message: Data(timestamp.utf8))
        let keyService = hmac256(key: keyDate, message: Data(nonce.utf8))
        let keySigning = hmac256(key: keyService, message: Data("ms_request".utf8))
        let signature = hmac256(key: keySigning, message: Data(canonicalRequestHex.utf8))
        return signature.map { String(format: "%02hhx", $0) }.joined()
    }

    public static func generateHeaders(secretId: String,
                                       secretKey: String,
                                       method: String,
                                       host: String,
                                       params: [String: Any],
                                       token: String?,
                                       nonce: String,
                                       timeMillis: Int64) -> [String: String]? {

        let contentType: String
        let canonicalQueryString: String
        if method.uppercased() == "GET" {
            contentType = "application/x-www-form-urlencoded"
            var paramStr: [String: String] = [:]
            if let pDic = params.compactMapValues { "\($0)" } as? [String: String] {
                paramStr = pDic
            } else {
                log.error("params type error")
            }
            canonicalQueryString = getCanonicalQueryString(params: paramStr)
        } else if method.uppercased() == "POST" {
            contentType = "application/json; charset=utf-8"
            canonicalQueryString = ""
        } else {
            return nil
        }

        var signedHeaderMap: [String: String] = [
            "X-MS-Version": "V2",
            "X-MS-Nonce": nonce,
            "X-MS-Timestamp": "\(timeMillis)",
            "Host": host,
            "Content-Type": contentType
        ]
        if let token = token {
//            signedHeaderMap["token"] = token
        }

        let lowerMap = signedHeaderMap.mapKeys { $0.lowercased() }
        let sortedKeys = lowerMap.keys.sorted()

        let signedHeaders = sortedKeys.joined(separator: ";")
        let canonicalHeaders = sortedKeys.map { "\($0):\(lowerMap[$0]!)" }.joined(separator: "\n")
        let payloadString: String
        if method.uppercased() == "POST" {
            guard let data = JSONSerialization.safeData(withJSONObject: params, options: [.sortedKeys]),
                  let json = String(data: data, encoding: .utf8) else { return nil }
            payloadString = json
        } else {
            payloadString = ""
        }
        let hashedPayload = sha256Hex(Data(payloadString.utf8))
        let canonicalRequest = """
        \(method)
        \(canonicalQueryString)
        \(canonicalHeaders)
        \(signedHeaders)
        \(hashedPayload)
        """

        let canonicalRequestHex = sha256Hex(Data(canonicalRequest.utf8))
        let signature = generateSign(secretKey: secretKey, timestamp: "\(timeMillis)", nonce: nonce, canonicalRequestHex: canonicalRequestHex)

        let authorization = "MS-HMAC-SHA256 Credential=\(secretId),SignedHeaders=\(signedHeaders),Signature=\(signature)"
        
//        let msg = "MsAuthTrans [method=\(method), signedHeaderMap=\(signedHeaderMap), payload=\(payloadString), paramMap=\(params), secretId=\(secretId), secretKey=\(secretKey), timestamp=\(timeMillis), nonce=\(nonce)] authorization:\(authorization)"
//        log.info(msg)
        var headers = signedHeaderMap
        headers["Authorization"] = authorization
        return headers
    }
}

// Helper extension
private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: self.map { (transform($0.key), $0.value) })
    }
}
