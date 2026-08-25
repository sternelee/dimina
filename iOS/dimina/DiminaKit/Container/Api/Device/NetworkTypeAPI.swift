//
//  NetworkTypeAPI.swift
//  dimina
//
//  Created by DosLin on 2025/5/10.
//

import Foundation
import Network
import CoreTelephony

/**
 * Device - Network API
 */
public class NetworkTypeAPI: DMPContainerApi {
    
    // API method names
    private static let GET_NETWORK_TYPE = "getNetworkType"
    private static let ON_NETWORK_STATUS_CHANGE = "onNetworkStatusChange"
    private static let OFF_NETWORK_STATUS_CHANGE = "offNetworkStatusChange"

    private final class Subscription {
        let monitor = NWPathMonitor()
        let queue: DispatchQueue
        var callbacks: [String: DMPBridgeCallback] = [:]

        init(appId: String) {
            queue = DispatchQueue(label: "com.didi.dimina.network-status.\(appId)")
        }
    }

    private static let subscriptionLock = NSLock()
    private static var subscriptions: [String: Subscription] = [:]
    
    // Get network type
    @BridgeMethod(GET_NETWORK_TYPE)
    var getNetworkType: DMPBridgeMethodHandler = { param, env, callback in
        // 获取网络类型
        let networkType = NetworkTypeAPI.getNetworkTypeInfo()
        
        let result = DMPMap()
        result.set("errMsg", "\(NetworkTypeAPI.GET_NETWORK_TYPE):ok")
        result.set("networkType", networkType)
        DMPContainerApi.invokeSuccess(callback: callback, param: result)
        return DMPAsyncResult()
    }

    @BridgeMethod(ON_NETWORK_STATUS_CHANGE)
    var onNetworkStatusChange: DMPBridgeMethodHandler = { param, env, callback in
        let data = param.getMap()
        guard let callback,
              let callbackId = data.getString(key: "callbackId") ?? data.getString(key: "success"),
              !callbackId.isEmpty else {
            return DMPNoneResult()
        }

        NetworkTypeAPI.subscriptionLock.lock()
        let existing = NetworkTypeAPI.subscriptions[env.appId]
        let subscription = existing ?? NetworkTypeAPI.Subscription(appId: env.appId)
        subscription.callbacks[callbackId] = callback
        NetworkTypeAPI.subscriptions[env.appId] = subscription
        NetworkTypeAPI.subscriptionLock.unlock()

        if existing == nil {
            subscription.monitor.pathUpdateHandler = { path in
                let result = DMPMap()
                let type = NetworkTypeAPI.networkType(for: path)
                result.set("isConnected", path.status == .satisfied)
                result.set("networkType", type)
                NetworkTypeAPI.subscriptionLock.lock()
                let listeners = NetworkTypeAPI.subscriptions[env.appId]?.callbacks.values.map { $0 } ?? []
                NetworkTypeAPI.subscriptionLock.unlock()
                listeners.forEach { $0(result, .success) }
            }
            subscription.monitor.start(queue: subscription.queue)
        }
        return DMPNoneResult()
    }

    @BridgeMethod(OFF_NETWORK_STATUS_CHANGE)
    var offNetworkStatusChange: DMPBridgeMethodHandler = { param, env, _ in
        let callbackId = param.getMap().getString(key: "callbackId")
        NetworkTypeAPI.subscriptionLock.lock()
        guard let subscription = NetworkTypeAPI.subscriptions[env.appId] else {
            NetworkTypeAPI.subscriptionLock.unlock()
            return DMPNoneResult()
        }
        if let callbackId, !callbackId.isEmpty {
            subscription.callbacks.removeValue(forKey: callbackId)
        } else {
            subscription.callbacks.removeAll()
        }
        let shouldCancel = subscription.callbacks.isEmpty
        if shouldCancel {
            NetworkTypeAPI.subscriptions.removeValue(forKey: env.appId)
        }
        NetworkTypeAPI.subscriptionLock.unlock()
        if shouldCancel { subscription.monitor.cancel() }
        return DMPNoneResult()
    }

    public static func clearApp(_ appId: String) {
        subscriptionLock.lock()
        let subscription = subscriptions.removeValue(forKey: appId)
        subscriptionLock.unlock()
        subscription?.monitor.cancel()
    }
    
    // Helper method to get network type
    private static func getNetworkTypeInfo() -> String {
        // 使用 NWPathMonitor 检查当前网络状态
        let monitor = NWPathMonitor()
        var networkType = "unknown"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                networkType = "wifi"
            } else if path.usesInterfaceType(.cellular) {
                // 对于蜂窝网络，需要进一步确定具体类型 (2g, 3g, 4g, 5g)
                networkType = getCellularNetworkType()
            } else if path.usesInterfaceType(.wiredEthernet) {
                // 有线网络归类为 wifi
                networkType = "wifi"
            } else if path.status == .satisfied {
                networkType = "unknown"
            } else {
                networkType = "none"
            }
            
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "NetworkTypeMonitor")
        monitor.start(queue: queue)
        
        // 等待网络状态检查完成，最多等待1秒
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return networkType
    }

    private static func networkType(for path: NWPath) -> String {
        if path.status != .satisfied { return "none" }
        if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) { return "wifi" }
        if path.usesInterfaceType(.cellular) { return getCellularNetworkType() }
        return "unknown"
    }
    
    // 获取蜂窝网络类型 (2g, 3g, 4g, 5g)
    private static func getCellularNetworkType() -> String {
        let networkInfo = CTTelephonyNetworkInfo()
        
        if #available(iOS 12.0, *) {
            // iOS 12及以上版本使用 serviceCurrentRadioAccessTechnology
            guard let carriers = networkInfo.serviceCurrentRadioAccessTechnology else {
                return "unknown"
            }
            
            // 获取第一个可用的网络技术
            guard let radioAccessTechnology = carriers.values.first else {
                return "unknown"
            }
            
            return self.mapRadioTechnologyToNetworkType(radioAccessTechnology)
        } else {
            // iOS 12以下版本使用 currentRadioAccessTechnology
            guard let radioAccessTechnology = networkInfo.currentRadioAccessTechnology else {
                return "unknown"
            }
            
            return self.mapRadioTechnologyToNetworkType(radioAccessTechnology)
        }
    }
    
    // 将无线电技术映射到网络类型
    private static func mapRadioTechnologyToNetworkType(_ radioTechnology: String) -> String {
        switch radioTechnology {
        // 2G 网络
        case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
            return "2g"
            
        // 3G 网络
        case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA, 
             CTRadioAccessTechnologyCDMAEVDORev0, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB, 
             CTRadioAccessTechnologyeHRPD:
            return "3g"
            
        // 4G 网络
        case CTRadioAccessTechnologyLTE:
            return "4g"
            
        // 5G 网络 (iOS 14.1+)
        default:
            if #available(iOS 14.1, *) {
                if radioTechnology == CTRadioAccessTechnologyNRNSA || radioTechnology == CTRadioAccessTechnologyNR {
                    return "5g"
                }
            }
            return "unknown"
        }
    }
}
