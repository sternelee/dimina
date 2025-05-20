//
//  PermissionManager.swift
//  dimina
//
//  Created by Lehem on 2025/5/15
//

import Foundation
import Photos
import AVFoundation
import UIKit

/// 权限类型
public enum DMPPermissionType {
    case photoLibrary
    case camera
    case microphone
    case location
}

/// 权限状态
public enum DMPPermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
    case limited // iOS 14+ 相册有限访问权限
    case notAvailable // 设备不支持该权限
}

/// 权限管理类
public class DMPPermissionManager {
    
    /// 单例
    public static let shared = DMPPermissionManager()
    
    private init() {}
    
    /// 检查权限是否已在 Info.plist 中配置
    public func isPermissionConfigured(_ type: DMPPermissionType) -> Bool {
        let bundle = Bundle.main
        
        switch type {
        case .photoLibrary:
            return bundle.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") != nil
        case .camera:
            return bundle.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil
        case .microphone:
            return bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil
        case .location:
            return bundle.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil ||
                   bundle.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil ||
                   bundle.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") != nil
        }
    }
    
    /// 检查权限状态
    public func checkPermissionStatus(_ type: DMPPermissionType, completion: @escaping (DMPPermissionStatus) -> Void) {
        // 首先检查是否配置了权限描述
        guard isPermissionConfigured(type) else {
            completion(.restricted)
            return
        }
        
        switch type {
        case .photoLibrary:
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .notDetermined:
                completion(.notDetermined)
            case .authorized:
                completion(.authorized)
            case .denied:
                completion(.denied)
            case .restricted:
                completion(.restricted)
            case .limited:
                completion(.limited)
            @unknown default:
                completion(.notDetermined)
            }
            
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .notDetermined:
                completion(.notDetermined)
            case .authorized:
                completion(.authorized)
            case .denied:
                completion(.denied)
            case .restricted:
                completion(.restricted)
            @unknown default:
                completion(.notDetermined)
            }
            
        case .microphone:
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            switch status {
            case .notDetermined:
                completion(.notDetermined)
            case .authorized:
                completion(.authorized)
            case .denied:
                completion(.denied)
            case .restricted:
                completion(.restricted)
            @unknown default:
                completion(.notDetermined)
            }
            
        case .location:
            // 位置权限需要导入CoreLocation，这里简化处理
            completion(.notDetermined)
        }
    }
    
    /// 请求权限
    public func requestPermission(_ type: DMPPermissionType, completion: @escaping (DMPPermissionStatus) -> Void) {
        // 首先检查是否配置了权限描述
        guard isPermissionConfigured(type) else {
            completion(.restricted)
            return
        }
        
        switch type {
        case .photoLibrary:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .notDetermined:
                        completion(.notDetermined)
                    case .authorized:
                        completion(.authorized)
                    case .denied:
                        completion(.denied)
                    case .restricted:
                        completion(.restricted)
                    case .limited:
                        completion(.limited)
                    @unknown default:
                        completion(.notDetermined)
                    }
                }
            }
            
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(.authorized)
                    } else {
                        completion(.denied)
                    }
                }
            }
            
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(.authorized)
                    } else {
                        completion(.denied)
                    }
                }
            }
            
        case .location:
            // 位置权限需要导入CoreLocation，这里简化处理
            completion(.notDetermined)
        }
    }
    
    /// 打开设置页面
    public func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    /// 获取权限描述文本
    public func getPermissionDescription(_ type: DMPPermissionType) -> String? {
        let bundle = Bundle.main
        
        switch type {
        case .photoLibrary:
            return bundle.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String
        case .camera:
            return bundle.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
        case .microphone:
            return bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String
        case .location:
            return bundle.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") as? String
        }
    }
} 
