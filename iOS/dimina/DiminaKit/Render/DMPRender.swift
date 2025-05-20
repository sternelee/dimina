//
//  DMPRender.swift
//  dimina
//
//  Created by Lehem on 2025/4/22.
//

import Foundation
import SwiftUI
import WebKit

public class DMPRender: DMPWebViewDelegate {
    private var webviewsMap: [Int: DMPWebview] = [:]
    private weak var app: DMPApp?

    private lazy var invokeHandler: DMPWebViewInvoke = DMPWebViewInvoke(render: self)
    private lazy var publishHandler: DMPWebViewPublish = DMPWebViewPublish(render: self)

    public init(app: DMPApp? = nil) {
        self.app = app
    }

    public func getApp() -> DMPApp? {
        return app
    }

    public func createWebView(appName: String) -> DMPWebview {
        let webview = DMPWebview(delegate: self, appName: appName, appId: app?.getAppId() ?? "")
        webviewsMap[webview.getWebViewId()] = webview
        return webview
    }

    public func getWebView(byId id: Int) -> DMPWebview? {
        return webviewsMap[id]
    }

    // 执行JavaScript代码
    public func executeJavaScript(webViewId: Int, _ script: String, completionHandler: ((Any?, Error?) -> Void)? = nil) -> Void {
        webviewsMap[webViewId]?.executeJavaScript(script, completionHandler: completionHandler)
    }

    // 注册JavaScript方法，让Native可以监听到JavaScript的调用
    public func registerJSHandler(webViewId: Int, handlerName: String, callback: @escaping (Any) -> Void) {
        webviewsMap[webViewId]?.registerJSHandler(handlerName: handlerName, callback: callback)
    }

    // 为单个WebView设置JS桥接
    public func setupJSBridge(webViewId: Int) {
        guard let webview = webviewsMap[webViewId] else { return }

        // 注册handlers
        invokeHandler.registerInvokeHandler(webview: webview, webViewId: webViewId)
        publishHandler.registerPublishHandler(webview: webview)

        // 注入JavaScript代码
        invokeHandler.injectInvokeJavaScript(webview: webview)
        publishHandler.injectPublishJavaScript(webview: webview)
    }

    // 为DMPPage提供WebView视图
    public func getWebViewRepresentable(webViewId: Int) -> AnyView {
        if let webview = webviewsMap[webViewId] {
            // 使用 createWebView() 方法来创建完整的视图
            return AnyView(webview.createWebView())
        }
        return AnyView(Text("WebView未初始化").padding())
    }

    // DMPWebViewDelegate 协议实现 - 处理WebView加载完成事件
    public func webViewDidFinishLoad(webViewId: Int) {
        print("🔴 DMPRender: 网页加载完成")
        let webview = webviewsMap[webViewId]

        setupJSBridge(webViewId: webViewId)

        self.app?.container?.loadResourceService(webViewId: webViewId, pagePath: webview?.getPagePath() ?? "");
        self.app?.container?.loadResourceRender(webViewId: webViewId, pagePath: webview?.getPagePath() ?? "");
    }

    // DMPWebViewDelegate 协议实现 - 处理WebView加载失败事件
    public func webViewDidFailLoad(webViewId: Int, error: Error) {
        print("🔴 DMPRender: 网页加载失败: \(error.localizedDescription)")
    }

    public func fromContainer(data: DMPMap, webViewId: Int) {
        let webview = webviewsMap[webViewId]
        let dataString = data.toJsonString()
        webview?.executeJavaScript("DiminaRenderBridge.onMessage(\(dataString))", completionHandler: nil)
    }

    public func fromService(msg: String, webViewId: Int) {
        let webview = webviewsMap[webViewId]
        webview?.executeJavaScript("DiminaRenderBridge.onMessage(\(msg))", completionHandler: nil)
    }
}

