//
//  DMPWebview.swift
//  dimina
//
//  Created by Lehem on 2025/4/22.
//

import Foundation
import WebKit
import SwiftUI

// 定义WebView委托协议
public protocol DMPWebViewDelegate: AnyObject {
    func webViewDidFinishLoad(webViewId: Int)
    func webViewDidFailLoad(webViewId: Int, error: Error)
}

public class DMPWebview: NSObject, WKNavigationDelegate, WKScriptMessageHandler, ObservableObject {
    private var webView: WKWebView
    private weak var delegate: DMPWebViewDelegate?
    private var jsBridgeCallbacks: [String: (Any) -> Void] = [:]

    // 添加WebViewLogger成员变量
    private var logger: DMPWebViewLogger?

    private let webViewId: Int
    private var pagePath: String
    private var query: [String: Any] = [:]

    // 添加共享的 WKProcessPool
    private static let sharedProcessPool: WKProcessPool = {
        return WKProcessPool()
    }()

    // 添加默认配置方法
    private static func defaultConfiguration(appId: String) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        // 基本配置
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.suppressesIncrementalRendering = true

        // 文件访问配置
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        if #available(iOS 10.0, *) {
            config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        }

        // JavaScript 配置
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            config.preferences.javaScriptEnabled = true
        }

        // 使用共享的进程池
        config.processPool = sharedProcessPool

        // 注册自定义URL方案
        if #available(iOS 11.0, *) {
            config.setURLSchemeHandler(DiminaURLSchemeHandler(appId: appId), forURLScheme: "dimina")
            config.setURLSchemeHandler(DifileURLSchemeHandler(appId: appId), forURLScheme: "difile")
        }

        return config
    }

    // 修改 isLoading 为 @Published 属性，并设为 public
    @Published public private(set) var isLoading: Bool = true
    public let appName: String

    // 修改构造函数
    public init(delegate: DMPWebViewDelegate?, appName: String, appId: String) {
        let config = DMPWebview.defaultConfiguration(appId: appId)

        self.webView = WKWebView(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) {
            self.webView.isInspectable = true
        }
        self.delegate = delegate
        self.webViewId = DMPIdProvider.generateWebViewId()
        self.pagePath = ""
        self.appName = appName

        super.init()

        self.webView.navigationDelegate = self

        // 初始化日志记录器
        self.logger = DMPWebViewLogger(webView: self.webView, webViewId: self.webViewId)
    }

    // 设置delegate方法
    public func setDelegate(_ delegate: DMPWebViewDelegate?) {
        self.delegate = delegate
    }

    // 设置日志处理器代理
    public func setLoggerDelegate(_ delegate: DMPWebViewLoggerDelegate?) {
        self.logger?.setDelegate(delegate)
    }
    
    // 注入CSS JS IMG 资源
    private func injectResourceFixScript() {
        let resourceFixScript = WKUserScript(source: """
        (function() {
        
            function convertTodiminaURL(url) {
                if (!url) return url;
                
                if (url.startsWith('file:///')) {
                    const newUrl = 'dimina:///' + url.substring(8);
                    return newUrl;
                }
                
                if (url.startsWith('/')) {
                    const newUrl = 'dimina:///' + url.substring(1);
                    return newUrl;
                }
                
                return url;
            }

            // 拦截document.createElement
            const originalCreateElement = document.createElement;
            document.createElement = function(tagName) {
                const element = originalCreateElement.call(document, tagName);
                // 图片元素特别处理
                if (tagName.toLowerCase() === 'img') {
                    console.log('[DEBUG] 创建图片元素，开始拦截');
                    // 覆盖setAttribute方法
                    const originalSetAttribute = element.setAttribute;
                    element.setAttribute = function(name, value) {
                        if (name === 'src') {
                            if (value && (value.startsWith('file:///') || value.startsWith('/'))) {
                                value = convertTodiminaURL(value);
                                console.log('[DEBUG] 已转换src属性:', value);
                            }
                        }
                        return originalSetAttribute.call(this, name, value);
                    };
                    
                    // 覆盖src属性
                    const originalSrcDescriptor = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, 'src');
                    Object.defineProperty(element, 'src', {
                        get: function() {
                            return originalSrcDescriptor.get.call(this);
                        },
                        set: function(value) {
                            if (value && (value.startsWith('file:///') || value.startsWith('/'))) {
                                value = convertTodiminaURL(value);
                                console.log('[DEBUG] 已转换src值:', value);
                            }
                            return originalSrcDescriptor.set.call(this, value);
                        }
                    });
                }
                return element;
            };

            // 拦截document.head.append和appendChild
            const originalAppendChild = Node.prototype.appendChild;
            Node.prototype.appendChild = function(node) {
                // 在添加到DOM之前修复资源URL
                if (node.nodeName === 'LINK' && node.rel === 'stylesheet' && node.href && node.href.startsWith('file:///')) {
                    console.log('拦截CSS添加:', node.href);
                    node.href = 'dimina:' + node.href.substring(5);
                }
                else if (node.nodeName === 'SCRIPT' && node.src && node.src.startsWith('file:///')) {
                    console.log('拦截JS添加:', node.src);
                    node.src = 'dimina:' + node.src.substring(5);
                }
                else if (node.nodeName === 'IMG') {
                    console.log('[DEBUG] appendChild图片:', node.src);
                    if (node.src && (node.src.startsWith('file:///') || node.src.startsWith('/'))) {
                        node.src = convertTodiminaURL(node.src);
                        console.log('[DEBUG] appendChild后图片src:', node.src);
                    }
                }
                return originalAppendChild.call(this, node);
            };

            // 拦截Element.prototype.append
            if (Element.prototype.append) {
                const originalAppend = Element.prototype.append;
                Element.prototype.append = function() {
                    for (let i = 0; i < arguments.length; i++) {
                        const node = arguments[i];
                        if (node && node.nodeName) {
                            if (node.nodeName === 'LINK' && node.rel === 'stylesheet' && node.href && node.href.startsWith('file:///')) {
                                console.log('拦截CSS添加(append):', node.href);
                                node.href = 'dimina:' + node.href.substring(5);
                            }
                            else if (node.nodeName === 'SCRIPT' && node.src && node.src.startsWith('file:///')) {
                                console.log('拦截JS添加(append):', node.src);
                                node.src = 'dimina:' + node.src.substring(5);
                            }
                            else if (node.nodeName === 'IMG') {
                                console.log('[DEBUG] append图片:', node.src);
                                if (node.src && (node.src.startsWith('file:///') || node.src.startsWith('/'))) {
                                    node.src = convertTodiminaURL(node.src);
                                    console.log('[DEBUG] append后图片src:', node.src);
                                }
                            }
                        }
                    }
                    return originalAppend.apply(this, arguments);
                };
            }

            // 立即添加一个observer来监控动态添加的资源
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.type === 'childList') {
                        mutation.addedNodes.forEach(function(node) {
                            // 处理已添加到DOM的资源节点
                            if (node.nodeName === 'LINK' && node.rel === 'stylesheet' && node.href && node.href.startsWith('file:///')) {
                                console.log('发现未拦截的CSS:', node.href);
                                const newHref = 'dimina:' + node.href.substring(5);
                                node.href = newHref; // 尝试直接修改
                            }
                            else if (node.nodeName === 'SCRIPT' && node.src && node.src.startsWith('file:///')) {
                                console.log('发现未拦截的JS:', node.src);
                                // 对于脚本，可能需要移除并重新添加
                                const newSrc = 'dimina:' + node.src.substring(5);
                                node.src = newSrc;
                            }
                            else if (node.nodeName === 'IMG') {
                                console.log('[DEBUG] 观察到新图片:', node.src);
                                if (node.src && (node.src.startsWith('file:///') || node.src.startsWith('/'))) {
                                    node.src = convertTodiminaURL(node.src);
                                    console.log('[DEBUG] 处理后图片src:', node.src);
                                }
                            }
                        });
                    }
                    // 特别处理属性变化，检查图片src属性的变化
                    if (mutation.type === 'attributes' && 
                        mutation.target.nodeName === 'IMG' && 
                        mutation.attributeName === 'src') {
                        const img = mutation.target;
                        console.log('[DEBUG] 图片属性变化:', img.src);
                        if (img.src && (img.src.startsWith('file:///') || img.src.startsWith('/'))) {
                            img.src = convertTodiminaURL(img.src);
                            console.log('[DEBUG] 属性变化后图片src:', img.src);
                        }
                    }
                });
            });

            // 启动观察器，同时监控属性变化
            observer.observe(document, {
                childList: true,
                subtree: true,
                attributes: true,
                attributeFilter: ['src']
            });

            // 在文档加载完成和资源加载前处理现有图片
            document.querySelectorAll('img').forEach(function(img) {
                console.log('[DEBUG] 处理现有图片:', img.src);
                if (img.src && (img.src.startsWith('file:///') || img.src.startsWith('/'))) {
                    img.src = convertTodiminaURL(img.src);
                    console.log('[DEBUG] 处理后图片src:', img.src);
                }
            });
            
            // 检查页面上的图片标签
            document.addEventListener('DOMContentLoaded', function() {
                console.log('[DEBUG] DOMContentLoaded触发，查找图片');
                const imgs = document.querySelectorAll('img');
                console.log('[DEBUG] 找到图片数量:', imgs.length);
                imgs.forEach(function(img, index) {
                    console.log(`[DEBUG] 图片${index} src:`, img.src);
                    if (img.src && (img.src.startsWith('file:///') || img.src.startsWith('/'))) {
                        const oldSrc = img.src;
                        img.src = convertTodiminaURL(img.src);
                        console.log(`[DEBUG] 图片${index} 转换: ${oldSrc} -> ${img.src}`);
                    }
                });
            });
            
        })();
        """, injectionTime: .atDocumentStart, forMainFrameOnly: false)

        webView.configuration.userContentController.addUserScript(resourceFixScript)
    }

    public func loadPageFrame() {
        injectResourceFixScript()

        let fileURL = URL(fileURLWithPath: DMPSandboxManager.sdkPageFramePath())
        let sandboxURL = URL(fileURLWithPath: DMPSandboxManager.sandboxPath())

        print("fileURL: \(fileURL)")
        print("sandboxURL: \(sandboxURL)")

        // 使用 loadFileURL 加载文件，并允许访问整个沙盒目录
        webView.loadFileURL(fileURL, allowingReadAccessTo: sandboxURL)
    }

    // 注册一个JS消息处理器，允许JS调用native方法
    public func registerJSHandler(handlerName: String, callback: @escaping (Any) -> Void) {
        webView.configuration.userContentController.add(self, name: handlerName)
        jsBridgeCallbacks[handlerName] = callback
    }

    // 执行JavaScript代码
    public func executeJavaScript(_ script: String, completionHandler: ((Any?, Error?) -> Void)? = nil) -> Void {
        if Thread.isMainThread {
            webView.evaluateJavaScript(script, completionHandler: completionHandler)
        } else {
            DispatchQueue.main.async {
                self.webView.evaluateJavaScript(script, completionHandler: completionHandler)
            }
        }
    }

    // WKScriptMessageHandler实现
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let callback = jsBridgeCallbacks[message.name] {
            callback(message.body)
        }
    }

    // WKNavigationDelegate实现 - 使用delegate模式替代直接依赖
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("网页加载完成")
        // 通过delegate回调通知网页加载完成
        delegate?.webViewDidFinishLoad(webViewId: self.webViewId)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("网页加载失败: \(error.localizedDescription)")
        // 添加详细的错误信息记录
        let errorInfo: [String: Any] = [
            "message": error.localizedDescription,
            "domain": (error as NSError).domain,
            "code": (error as NSError).code,
            "userInfo": (error as NSError).userInfo,
            "webViewId": self.webViewId
        ]
        print("详细错误信息: \(errorInfo)")
        // 通过delegate回调通知网页加载失败
        delegate?.webViewDidFailLoad(webViewId: self.webViewId, error: error)
    }

    // 使用自定义URL方案处理资源加载
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // 空实现，允许所有导航请求
        decisionHandler(.allow)
    }

    // 获取底层WKWebView
    public func getWebView() -> WKWebView {
        return webView
    }

    // 获取WebView的唯一ID
    public func getWebViewId() -> Int {
        return webViewId
    }

    // 获取WebView的页面路径
    public func getPagePath() -> String {
        return self.pagePath
    }

    public func setPagePath(pagePath: String) {
        self.pagePath = pagePath
    }

    public func getQuery() -> [String: Any] {
        return self.query
    }

    public func setQuery(query: [String: Any]) {
        self.query = query
    }

    // SwiftUI视图包装器
    public struct WebViewRepresentable: UIViewRepresentable {
        @ObservedObject var webview: DMPWebview  // 使用 @ObservedObject

        public init(webview: DMPWebview) {
            self.webview = webview
        }

        public func makeUIView(context: Context) -> WKWebView {
            return webview.getWebView()
        }

        public func updateUIView(_ uiView: WKWebView, context: Context) {
            // 更新UI视图（如果需要）
        }
    }

    deinit {
        // 清理注册的消息处理器
        for handlerName in jsBridgeCallbacks.keys {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: handlerName)
        }
        // 清理日志记录器
        logger?.cleanup()
        logger = nil
    }

    // 修改 hideLoading 方法
    public func hideLoading() {
        if Thread.isMainThread {
            withAnimation(.easeOut(duration: 0.3)) {
                self.isLoading = false
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isLoading = false
                }
            }
        }
    }

    public struct WebViewContainer: View {
        @ObservedObject var webview: DMPWebview
        var isRoot: Bool = false

        public init(webview: DMPWebview, isRoot: Bool = false) {
            self.webview = webview
            self.isRoot = isRoot
        }

        public var body: some View {
            ZStack {
                WebViewRepresentable(webview: webview)

                if webview.isLoading && isRoot {
                    DMPLoadingView(appName: webview.appName)
                        .transition(.opacity)
                }
            }
            .onChange(of: webview.isLoading) { newValue in
                print("🔴 DMPWebview: isLoading changed to \(newValue)")
            }
        }
    }

    public func createWebView(isRoot: Bool = false) -> some View {
        WebViewContainer(webview: self, isRoot: isRoot)
    }
}

public struct DMPLoadingView: View {
    let appName: String
    @State private var rotation: Double = 0.0
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    public var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: 60, height: 60)

                    Circle()
                        .fill(DMPUtil.generateColorFromName(name: appName))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(appName.prefix(1)))
                                .font(.system(size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )

                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .offset(y: -30)
                        .rotationEffect(.degrees(rotation))
                }
                .frame(width: 60, height: 60)

                Text(appName)
                    .font(.system(size: 14))
                    .fontWeight(.medium)
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                rotation += 3.0
            }
        }
    }
}

#Preview("LoadingView") {
    DMPLoadingView(appName: "测试应用")
}
