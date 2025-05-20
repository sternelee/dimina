//
//  DMPIdProvider.swift
//  dimina
//
//  Created by Lehem on 2025/4/23.
//

import Foundation

public class DMPIdProvider {
    private static var _stackId: Int = 0
    private static var _webviewId: Int = 0
    
    // 获取当前的栈ID
    public static var stackId: Int {
        return _stackId
    }
    
    // 增加栈ID计数
    public static func increaseStackId() {
        _stackId += 1
    }
    
    // 生成新的栈ID并返回
    public static func generateStackId() -> Int {
        increaseStackId()
        return _stackId
    }
    
    // 获取当前的WebView ID
    public static var webViewId: Int {
        return _webviewId
    }
    
    // 生成新的WebView ID并返回
    public static func generateWebViewId() -> Int {
        increaseWebViewId()
        return _webviewId
    }
    
    // 增加WebView ID计数
    public static func increaseWebViewId() {
        _webviewId += 1
    }
} 