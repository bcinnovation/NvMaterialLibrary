//
//  NvReachability.swift
//  NvNetwork
//
//  Created by chengww on 2022/4/12.
//

import Foundation
import Network

// iOS12
public class NvReachability {
    public typealias NvReachabilityStatus = (Bool) -> Void
    public static let `default` = NvReachability()

    public var statusListener: NvReachabilityStatus?

    public var isReachable: Bool {
        monitor.currentPath.status == .satisfied
    }

    @discardableResult
    public func startNotifier() -> Bool {
        guard !isMonitoring else { return false }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let reachable = path.status == .satisfied
            self.statusListener?(reachable)
        }
        monitor.start(queue: queue)
        return true
    }

    public func stopNotifier() {
        guard isMonitoring else { return }
        isMonitoring = false

        monitor.cancel()
        // ⚠️ NWPathMonitor 只能使用一次，需要重新创建
        monitor = NWPathMonitor()
    }

    // MARK: - Private
    private var monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.nv.reachability.monitor")
    private var isMonitoring = false

    private init() {
        self.monitor = NWPathMonitor()
    }
}
