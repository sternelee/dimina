//
//  DMPWebViewPublish.swift
//  dimina
//
//  Created by Lehem on 2025/4/27.
//

import Foundation
import WebKit

public class DMPWebViewPublish {
    // 保存webView实例的引用
    private weak var render: DMPRender?
        
    public init(render: DMPRender) {
        self.render = render
    }
    
    public func registerPublishHandler(webview: DMPWebview) {
        webview.registerJSHandler(handlerName: "publishHandler") { [weak self] data in
            guard let self = self else { return }
            
            print("🔴 DiminaRenderBridge.publish: \(data)")
            
            if let message = data as? String {   
                Task {
                    await DMPChannelProxy.renderToService(msg: message, app: self.render?.getApp())
                }
            } else {
                print("publish消息格式不正确，期望字符串类型: \(data)")
            }
        }
    }
    
    public func injectPublishJavaScript(webview: DMPWebview) {
        let publishScript = """
        // 添加publish方法
        window.DiminaRenderBridge = window.DiminaRenderBridge || {};
        window.DiminaRenderBridge.publish = function(msg) {
            if (typeof msg !== 'string') {
                console.error('DiminaRenderBridge.publish: 消息必须是字符串类型', msg);
                return;
            }
            
            window.webkit.messageHandlers.publishHandler.postMessage(msg);
        };
        """
        
        webview.executeJavaScript(publishScript)
    }    
} 
