//
//  DMPWebViewLogger.swift
//  dimina
//
//  Created by Lehem on 2025/4/22.
//

import Foundation
import WebKit

// 日志级别定义
public enum DMPLogLevel: String {
    case log = "LOG"
    case error = "ERROR"
    case warn = "WARN"
    case info = "INFO"
    case network = "NETWORK"
    case resource = "RESOURCE"
}

// WebView日志委托协议
public protocol DMPWebViewLoggerDelegate: AnyObject {
    func webViewDidLog(webViewId: Int, level: DMPLogLevel, message: String)
}

// 为日志方法提供默认实现
public extension DMPWebViewLoggerDelegate {
    func webViewDidLog(webViewId: Int, level: DMPLogLevel, message: String) {
        print("🔵 WebView[\(webViewId)] [\(level.rawValue)]: \(message)")
    }
}

public class DMPWebViewLogger: NSObject, WKScriptMessageHandler {
    private var webView: WKWebView
    private weak var delegate: DMPWebViewLoggerDelegate?
    private let webViewId: Int
    
    public init(webView: WKWebView, webViewId: Int, delegate: DMPWebViewLoggerDelegate? = nil) {
        self.webView = webView
        self.webViewId = webViewId
        self.delegate = delegate
        super.init()
        
        setupLogHandlers()
    }
    
    // 设置日志处理器
    private func setupLogHandlers() {
        // 注册消息处理器
        webView.configuration.userContentController.add(self, name: "consoleLog")
        webView.configuration.userContentController.add(self, name: "consoleError")
        webView.configuration.userContentController.add(self, name: "consoleWarn")
        webView.configuration.userContentController.add(self, name: "consoleInfo")
        webView.configuration.userContentController.add(self, name: "jsError")
        webView.configuration.userContentController.add(self, name: "networkError")
        webView.configuration.userContentController.add(self, name: "resourceError")
        
        // 配置WebView安全设置
        if #available(iOS 14.0, *) {
            // 新版本iOS使用标准API
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            webView.configuration.defaultWebpagePreferences = pagePrefs
            
            // 启用开发者工具（如果支持）
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
            
            print("WebView已配置为现代安全模式")
        } else {
            // 注意：这里不再使用私有API，因为它们可能导致崩溃
            print("WebView使用默认安全设置")
        }
        
        // 注入日志捕获脚本
        injectLoggerScript()
        
        // 在首次导航完成后注入额外的JavaScript以处理跨域问题
        print("WebView日志处理器初始化完成")
    }
    
    // 注入日志捕获脚本
    private func injectLoggerScript() {
        let script = WKUserScript(source: getLoggerScript(), injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
    }
    
    // 获取日志捕获脚本
    private func getLoggerScript() -> String {
        return """
        // 重写console方法和捕获错误的JavaScript
        (function() {
            // 解决"Script error."问题 - 标记所有脚本为可跨域
            try {
                // 尝试添加全局处理器使动态添加的script元素具有crossorigin属性
                document.addEventListener('beforescriptexecute', function(e) {
                    if (e.target && !e.target.hasAttribute('crossorigin')) {
                        e.target.setAttribute('crossorigin', 'anonymous');
                        console.log('Added crossorigin to:', e.target.src || 'inline script');
                    }
                }, true);
            } catch(e) {
                // beforescriptexecute可能不被所有浏览器支持
                console.log('CrossOrigin auto-fix not supported in this browser');
            }
            
            // 监控动态创建的script元素并添加crossorigin
            const originalCreateElement = document.createElement;
            document.createElement = function(tagName) {
                const element = originalCreateElement.call(document, tagName);
                if (tagName.toLowerCase() === 'script') {
                    setTimeout(function() {
                        if (!element.hasAttribute('crossorigin')) {
                            element.setAttribute('crossorigin', 'anonymous');
                        }
                    }, 0);
                }
                return element;
            };
            
            var originalLog = console.log;
            var originalError = console.error;
            var originalWarn = console.warn;
            var originalInfo = console.info;
            
            // 构造消息时添加更多上下文
            function enhanceLogMessage() {
                var args = Array.from(arguments);
                var callerInfo = '';
                
                try {
                    throw new Error('_getCallerInfo_');
                } catch(e) {
                    if (e.stack) {
                        var stackLines = e.stack.split('\\n');
                        if (stackLines.length > 2) {
                            // 跳过当前函数和console包装函数
                            callerInfo = stackLines[2].trim();
                            // 提取源文件和行号
                            var matches = callerInfo.match(/at\\s+(.+)$/);
                            if (matches && matches[1]) {
                                callerInfo = '[' + matches[1] + '] ';
                            }
                        }
                    }
                }
                
                return callerInfo + args.map(String).join(' ');
            }
            
            console.log = function() {
                var message = enhanceLogMessage.apply(this, arguments);
                window.webkit.messageHandlers.consoleLog.postMessage(message);
                originalLog.apply(console, arguments);
            };
            
            console.error = function() {
                var message = enhanceLogMessage.apply(this, arguments);
                window.webkit.messageHandlers.consoleError.postMessage(message);
                originalError.apply(console, arguments);
            };
            
            console.warn = function() {
                var message = enhanceLogMessage.apply(this, arguments);
                window.webkit.messageHandlers.consoleWarn.postMessage(message);
                originalWarn.apply(console, arguments);
            };
            
            console.info = function() {
                var message = enhanceLogMessage.apply(this, arguments);
                window.webkit.messageHandlers.consoleInfo.postMessage(message);
                originalInfo.apply(console, arguments);
            };
            
            // 启用跨域详细错误信息
            window.addEventListener('error', function(event) {
                // 添加crossorigin属性以获取更多跨域错误信息
                if (event.target && (event.target.tagName === 'SCRIPT' || event.target.tagName === 'LINK' || event.target.tagName === 'IMG')) {
                    event.target.crossOrigin = 'anonymous';
                }
                
                var errorData = {
                    message: event.message || 'Unknown Error',
                    filename: event.filename || '',
                    lineno: event.lineno || 0,
                    colno: event.colno || 0,
                    stack: event.error ? (event.error.stack || '') : '',
                    target: event.target ? event.target.tagName || '' : '',
                    timeStamp: event.timeStamp,
                    type: event.type
                };
                
                if (event.error) {
                    // 获取更多错误属性
                    Object.getOwnPropertyNames(event.error).forEach(function(key) {
                        try {
                            errorData[key] = String(event.error[key]);
                        } catch(e) {
                            errorData[key] = 'Could not stringify property';
                        }
                    });
                }
                
                window.webkit.messageHandlers.jsError.postMessage(JSON.stringify(errorData));
            }, true);  // 使用捕获阶段以获取所有事件
            
            // 捕获未处理的Promise拒绝
            window.addEventListener('unhandledrejection', function(event) {
                var errorData = {
                    message: 'Unhandled Promise Rejection: ' + (event.reason ? String(event.reason) : 'Unknown'),
                    stack: event.reason && event.reason.stack ? event.reason.stack : '',
                    reason: event.reason ? String(event.reason) : '',
                    timeStamp: event.timeStamp,
                    type: 'unhandledrejection'
                };
                
                // 获取更多Rejection详情
                if (event.reason && typeof event.reason === 'object') {
                    try {
                        Object.getOwnPropertyNames(event.reason).forEach(function(key) {
                            try {
                                errorData['reason_' + key] = String(event.reason[key]);
                            } catch(e) {
                                errorData['reason_' + key] = 'Could not stringify property';
                            }
                        });
                    } catch(e) {
                        errorData.reasonError = String(e);
                    }
                }
                
                window.webkit.messageHandlers.jsError.postMessage(JSON.stringify(errorData));
            });
            
            // 监控网络请求错误
            window.addEventListener('error', function(event) {
                if (event.target && (event.target.tagName === 'IMG' || event.target.tagName === 'SCRIPT' || event.target.tagName === 'LINK' || event.target.tagName === 'IFRAME')) {
                    var resourceData = {
                        element: event.target.tagName,
                        url: event.target.src || event.target.href,
                        timeStamp: event.timeStamp,
                        error: event.message,
                        type: 'resourceError'
                    };
                    window.webkit.messageHandlers.resourceError.postMessage(JSON.stringify(resourceData));
                }
            }, true);
            
            // 记录"Script error"错误的可能原因
            if (window.location.protocol === 'file:') {
                console.warn('Running from file:// protocol - this may cause "Script error" messages due to security restrictions');
            }
            
            // 记录页面基本信息，帮助调试
            console.info('Page URL: ' + location.href);
            console.info('User Agent: ' + navigator.userAgent);
            
            // 监听XHR请求错误
            (function() {
                var originalXHROpen = XMLHttpRequest.prototype.open;
                var originalXHRSend = XMLHttpRequest.prototype.send;
                
                XMLHttpRequest.prototype.open = function(method, url) {
                    this._diminaUrl = url;
                    this._diminaMethod = method;
                    return originalXHROpen.apply(this, arguments);
                };
                
                XMLHttpRequest.prototype.send = function() {
                    var xhr = this;
                    this.addEventListener('error', function() {
                        var networkData = {
                            type: 'xhr_error',
                            url: xhr._diminaUrl || 'unknown',
                            method: xhr._diminaMethod || 'unknown',
                            status: xhr.status,
                            statusText: xhr.statusText,
                            readyState: xhr.readyState,
                            responseType: xhr.responseType,
                            timeStamp: Date.now()
                        };
                        window.webkit.messageHandlers.networkError.postMessage(JSON.stringify(networkData));
                    });
                    
                    // 记录请求完成但状态码异常的情况
                    this.addEventListener('load', function() {
                        if (xhr.status >= 400) {
                            var networkData = {
                                type: 'xhr_status_error',
                                url: xhr._diminaUrl || 'unknown',
                                method: xhr._diminaMethod || 'unknown',
                                status: xhr.status,
                                statusText: xhr.statusText,
                                readyState: xhr.readyState,
                                responseText: (xhr.responseType === '' || xhr.responseType === 'text') ? xhr.responseText.substring(0, 500) : '(binary)',
                                timeStamp: Date.now()
                            };
                            window.webkit.messageHandlers.networkError.postMessage(JSON.stringify(networkData));
                        }
                    });
                    
                    return originalXHRSend.apply(this, arguments);
                };
            })();
            
            // 监听Fetch请求错误
            (function() {
                var originalFetch = window.fetch;
                window.fetch = function() {
                    var url = arguments[0];
                    var options = arguments[1] || {};
                    
                    if (typeof url === 'object') {
                        url = url.url;
                    }
                    
                    return originalFetch.apply(this, arguments)
                        .catch(function(error) {
                            var networkData = {
                                type: 'fetch_error',
                                url: url,
                                method: options.method || 'GET',
                                error: String(error),
                                stack: error.stack || '',
                                timeStamp: Date.now()
                            };
                            window.webkit.messageHandlers.networkError.postMessage(JSON.stringify(networkData));
                            throw error;
                        });
                };
            })();
        })();
        """
    }
    
    // 设置delegate
    public func setDelegate(_ delegate: DMPWebViewLoggerDelegate?) {
        self.delegate = delegate
    }
    
    // WKScriptMessageHandler实现
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // 根据消息类型处理日志
        if message.name.starts(with: "console") {
            let levelStr = message.name.replacingOccurrences(of: "console", with: "")
            var level: DMPLogLevel = .log
            
            switch levelStr.lowercased() {
            case "error":
                level = .error
            case "warn":
                level = .warn
            case "info":
                level = .info
            default:
                level = .log
            }
            
            if let messageContent = message.body as? String {
                logMessage(level: level, message: messageContent)
            }
        } else if message.name == "jsError" {
            if let errorJSON = message.body as? String {
                processJSError(errorJSON: errorJSON)
            }
        } else if message.name == "networkError" || message.name == "resourceError" {
            if let errorJSON = message.body as? String {
                processNetworkError(errorJSON: errorJSON)
            }
        }
    }
    
    // 处理JS错误
    private func processJSError(errorJSON: String) {
        print("🔵 WebView[\(self.webViewId)] [ERROR]: \(errorJSON)")
        
        guard let data = errorJSON.data(using: .utf8),
              let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logMessage(level: .error, message: "无法解析JS错误: \(errorJSON)")
            return
        }
        
        // 构造更详细的错误信息
        var detailedMessage = "JS Error:\n"
        if let message = errorDict["message"] as? String {
            detailedMessage += "Message: \(message)\n"
        }
        if let filename = errorDict["filename"] as? String, !filename.isEmpty {
            detailedMessage += "File: \(filename)\n"
        }
        if let lineno = errorDict["lineno"] as? Int, lineno > 0 {
            detailedMessage += "Line: \(lineno)\n"
        }
        if let colno = errorDict["colno"] as? Int, colno > 0 {
            detailedMessage += "Column: \(colno)\n"
        }
        if let target = errorDict["target"] as? String, !target.isEmpty {
            detailedMessage += "Target: \(target)\n"
        }
        if let type = errorDict["type"] as? String {
            detailedMessage += "Type: \(type)\n"
        }
        if let stack = errorDict["stack"] as? String, !stack.isEmpty {
            detailedMessage += "Stack:\n\(stack)\n"
        }
        
        // 添加其他可能的错误属性
        for (key, value) in errorDict {
            if !["message", "filename", "lineno", "colno", "stack", "target", "type"].contains(key) {
                if let stringValue = value as? String, !stringValue.isEmpty {
                    detailedMessage += "\(key): \(stringValue)\n"
                }
            }
        }
        
        logMessage(level: .error, message: detailedMessage)
    }
    
    // 处理网络错误
    private func processNetworkError(errorJSON: String) {
        print("🔵 WebView[\(self.webViewId)] [NETWORK_ERROR]: \(errorJSON)")
        
        guard let data = errorJSON.data(using: .utf8),
              let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logMessage(level: .network, message: "无法解析网络错误: \(errorJSON)")
            return
        }
        
        var detailedMessage = "Network Error:\n"
        for (key, value) in errorDict {
            if let stringValue = value as? String {
                detailedMessage += "\(key): \(stringValue)\n"
            } else {
                detailedMessage += "\(key): \(value)\n"
            }
        }
        
        logMessage(level: .network, message: detailedMessage)
    }
    
    // 记录日志消息
    private func logMessage(level: DMPLogLevel, message: String) {
        delegate?.webViewDidLog(webViewId: webViewId, level: level, message: message)
        print("🔵 WebView[\(webViewId)] [\(level.rawValue)]: \(message)")
    }
    
    // 清理
    public func cleanup() {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "consoleLog")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "consoleError")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "consoleWarn")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "consoleInfo")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "jsError")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "networkError")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "resourceError")
    }
    
    deinit {
        cleanup()
    }
} 
