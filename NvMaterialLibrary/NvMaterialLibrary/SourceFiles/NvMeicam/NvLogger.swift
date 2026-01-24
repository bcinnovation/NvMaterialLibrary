//
//  NvLogger.swift
//  NvEditor
//
//  Created by chengww on 2022/1/17.
//

import UIKit

public extension NvLogger {
    enum Level: Int {
        case trace = 0
        case debug = 1
        case info = 2
        case warn = 3
        case error = 4
    }
}

public class NvLogger {
    public static func with(_ identifier: String) -> NvLogger {
        guard let instance = _instances[identifier] else {
            let instance = NvLogger(id: identifier)
            _instances[identifier] = instance
            return instance
        }
        return instance
    }
    
    public func set(level: Level = .trace) {
        NvConsoleAppender.sharedInstance().level = level
    }
    
    public static func dispose(_ identifier: String) {
        _ = _instances.removeValue(forKey: identifier)
        if _instances.isEmpty {
            NvConsoleAppender.sharedConsoleAppender = nil
        }
    }
    
    fileprivate var identifier: String = ""
    private static var _instances: [String: NvLogger] = [:]
    private init(id: String) {
        identifier = id
    }
}

public extension NvLogger {
    func trace(_ message: Any..., file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .trace,
                                                  message: message,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
    
    func trace(format: String, arguments: CVarArg, file: StaticString = #file, function: StaticString = #function,
               line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .trace,
                                                  format: format,
                                                  arguments: arguments,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
    
    func debug(_ message: Any..., file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self, msgLevel: .debug, message: message, file: file, function: function, line: line)
    }
    
    func debug(format: String,
               arguments: CVarArg,
               file: StaticString = #file,
               function: StaticString = #function,
               line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .debug,
                                                  format: format,
                                                  arguments: arguments,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
    
    func info(_ message: Any...,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .info,
                                                  message: message,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
    
    func info(format: String,
              arguments: CVarArg,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .info,
                                                  format: format,
                                                  arguments: arguments,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
    
    func warn(_ message: Any..., file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .warn,
                                                  message: message,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
    
    func warn(format: String,
              arguments: CVarArg,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .warn,
                                                  format: format,
                                                  arguments: arguments,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
    
    func error(_ message: Any...,
               file: StaticString = #file,
               function: StaticString = #function,
               line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .error,
                                                  message: message,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
    
    func error(format: String,
               arguments: CVarArg,
               file: StaticString = #file,
               function: StaticString = #function,
               line: Int = #line) {
        NvConsoleAppender.sharedInstance().append(self,
                                                  msgLevel: .error,
                                                  format: format,
                                                  arguments: arguments,
                                                  file: file,
                                                  function: function,
                                                  line: line)
    }
}

internal final class NvConsoleAppender {
    var level: NvLogger.Level = .trace
    static var sharedConsoleAppender: NvConsoleAppender?
    static func sharedInstance() -> NvConsoleAppender {
        guard let instance = sharedConsoleAppender else {
            sharedConsoleAppender = NvConsoleAppender()
            return sharedConsoleAppender!
        }
        return instance
    }
    
    func append(_ logboard: NvLogger,
                msgLevel: NvLogger.Level,
                message: [Any],
                file: StaticString,
                function: StaticString,
                line: Int) {
        if msgLevel.rawValue < level.rawValue {
            return
        }
        print(dateFormatter.string(from: Date()), "\(logboard.identifier):\(levelString(msgLevel))",
              "\(filename(file.description)):\(function)-line\(line)\n",
              message.map { String(describing: $0) }.joined(separator: ""))
    }
    
    func append(_ logboard: NvLogger,
                msgLevel: NvLogger.Level,
                format: String,
                arguments: CVarArg,
                file: StaticString,
                function: StaticString,
                line: Int) {
        if msgLevel.rawValue < level.rawValue {
            return
        }
        print(dateFormatter.string(from: Date()), "\(logboard.identifier):\(levelString(msgLevel))",
              "\(filename(file.description)):\(function)-line\(line)\n", String(format: format, arguments))
    }
    
    private var traceStr: String
    private var debugStr: String
    private var infoStr: String
    private var warnStr: String
    private var errorStr: String
    public init() {
        traceStr = "Trace 💜"
        debugStr = "Debug 💙"
        infoStr = "Info 💚"
        warnStr = "Warn 💛"
        errorStr = "Error ❤️"
    }
    
    func setLevelString(_ levelType: NvLogger.Level, str: String) {
        switch levelType {
        case .trace:
            traceStr = str
        case .debug:
            debugStr = str
        case .info:
            infoStr = str
        case .warn:
            warnStr = str
        case .error:
            errorStr = str
        }
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-dd-MM HH:mm:ss.SSS"
        return dateFormatter
    }()
    
    private func levelString(_ level: NvLogger.Level) -> String {
        switch level {
        case .trace:
            return traceStr
        case .debug:
            return debugStr
        case .info:
            return infoStr
        case .warn:
            return warnStr
        case .error:
            return errorStr
        }
    }
    
    private func filename(_ file: String) -> String {
        file.components(separatedBy: "/").last ?? file
    }
}
