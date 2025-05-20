//
//  DMPEnginePublish.swift
//  dimina
//
//  Created by Lehem on 2025/4/18.
//

import Foundation
import JavaScriptCore

public class DMPEnginePublish {

    private static var appResolver: (() -> DMPApp?)?
    
    public static func registerAppResolver(_ resolver: @escaping () -> DMPApp?) {
        appResolver = resolver
    }
    
    public static func registerPublish(to context: JSContext) {
        // 定义publish函数
        let publish: @convention(block) (Int, JSValue) -> Void = { webViewId, d in     
            print("🔵 DiminaServiceBridge.publish调用: webViewId=\(webViewId), data=\(d)")

            if let dict = d.toDictionary() {
                if let jsonString = DMPUtil.jsonEncode(from: dict) {
                    let app = appResolver?()
                    DMPChannelProxy.serviceToRender(msg: jsonString, webViewId: webViewId, app: app);
                }
            }
        }
        
        let global = context.globalObject
        let bridge = global?.objectForKeyedSubscript("DiminaServiceBridge")
        
        // 设置publish方法
        bridge?.setObject(publish, forKeyedSubscript: "publish" as NSString)
        
        print("registerPublish 完成")
    }
} 
