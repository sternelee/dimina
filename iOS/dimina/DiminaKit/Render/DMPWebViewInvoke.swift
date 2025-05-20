//
//  DMPWebViewInvoke.swift
//  dimina
//
//  Created by Lehem on 2025/4/27.
//

import Foundation
import WebKit

public class DMPWebViewInvoke {
    // 保存webView实例的引用
    private weak var render: DMPRender?
        
    // 自定义的invokeHandler回调
    private var customInvokeHandler: ((String, [String: Any], String) -> Any)?
    
    public init(render: DMPRender) {
        self.render = render
    }
    
    // 设置invoke消息的处理函数
    public func setInvokeHandler(_ handler: @escaping (String, [String: Any], String) -> Any) {
        self.customInvokeHandler = handler
    }
    
    // 注册invoke处理器
    public func registerInvokeHandler(webview: DMPWebview, webViewId: Int) {
        webview.registerJSHandler(handlerName: "invokeHandler") { [weak self] data in
            guard let self = self else { return }

            print("🔴 DiminaRenderBridge.publish调用: \(data)")

            // 处理从JS传来的数据
            if let messageString = data as? String {
                // 解析JSON字符串
                if let messageData = messageString.data(using: .utf8),
                   let messageDict = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
                   let type = messageDict["type"] as? String,
                   let body = messageDict["body"] as? [String: Any],
                   let target = messageDict["target"] as? String {
                    
                    print("消息类型: \(type)")
                    print("消息内容: \(body)")
                    print("目标处理器: \(target)")
                    
                    // 获取回调ID
                    let callbackId = messageDict["callbackId"] as? String
                    if let callbackId = callbackId {
                        print("回调ID: \(callbackId)")
                    }
                    
                    // 处理消息并获取返回值
                    let result = self.processInvokeMessage(type: type, body: body, target: target)
                    
                    // 将结果返回给JS
                    if let callbackId = callbackId {
                        var resultJson = "null"
                        
                        // 根据返回值类型生成适当的JS表示
                        if let resultStr = result as? String {
                            // 字符串类型，需要加引号
                            resultJson = "\"\(resultStr)\""
                        } else if let resultNum = result as? NSNumber {
                            // 数字或布尔值
                            if CFGetTypeID(resultNum) == CFBooleanGetTypeID() {
                                // 布尔值
                                resultJson = resultNum.boolValue ? "true" : "false"
                            } else {
                                // 数字
                                resultJson = resultNum.stringValue
                            }
                        } else if let resultDict = result as? [String: Any] {
                            // 对象
                            resultJson = DMPUtil.jsonEncode(from: resultDict) ?? "null"
                        } else if let resultArray = result as? [Any] {
                            // 数组
                            resultJson = DMPUtil.jsonEncode(from: resultArray) ?? "null"
                        }
                        
                        let callbackScript = """
                        if (window['\(callbackId)']) {
                            window['\(callbackId)'](\(resultJson));
                        }
                        """
                        self.render?.executeJavaScript(webViewId: webViewId, callbackScript)
                    }
                } else {
                    print("无法解析JSON消息: \(messageString)")
                }
            }
        }
    }
    
    // 注入invoke相关的JavaScript代码
    public func injectInvokeJavaScript(webview: DMPWebview) {
        let invokeScript = """
        // 添加invoke方法
        window.DiminaRenderBridge = window.DiminaRenderBridge || {};
        window.DiminaRenderBridge.invoke = function(msg) {            
            if (typeof msg !== 'string') {
                console.error('DiminaRenderBridge.invoke: 消息必须是字符串类型', msg);
                return null;
            }
            
            return new Promise((resolve) => {
                const callbackId = 'cb_' + Date.now() + '_' + Math.floor(Math.random() * 1000);
                
                // 设置一次性回调函数
                window[callbackId] = function(result) {
                    resolve(result);
                    delete window[callbackId];
                };
                
                // 直接发送字符串消息到Native
                window.webkit.messageHandlers.invokeHandler.postMessage(msg);
            });
        };
        """
        
        webview.executeJavaScript(invokeScript)
    }
    
    public func processInvokeMessage(type: String, body: [String: Any], target: String) -> Any {
        if let app = self.render?.getApp() {
            let result = DMPChannelProxy.messageHandler(type: type, body: DMPMap.fromDict(dict: body), target: target, app: app)
            return result
        }

        return ["success": false, "message": "未知的消息类型或目标: \(type), \(target)"]
    }
} 
