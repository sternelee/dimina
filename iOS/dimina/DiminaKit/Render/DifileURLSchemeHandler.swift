//
//  DiminaURLSchemeHandler.swift
//  dimina
//
//  Created by Lehem on 2025/5/16.
//

import Foundation
import WebKit

@available(iOS 11.0, *)
class DifileURLSchemeHandler: NSObject, WKURLSchemeHandler {
    private let appId: String
    
    init(appId: String) {
        self.appId = appId
        super.init()
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "DiminaErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        guard let path = DMPFileUtil.sandboxPathFromVPath(from: url.absoluteString, appId: self.appId) else {
            let errorMessage = "无法获取资源路径"
            print("❌ \(errorMessage)")
            urlSchemeTask.didFailWithError(NSError(domain: "DiminaErrorDomain", code: 404, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            return
        }
        
        print("📦 DifileURLSchemeHandler loading resource: \(path)")
        
        // Check if the file exists
        guard FileManager.default.fileExists(atPath: path) else {
            let errorMessage = "Resource does not exist: \(path)"
            print("❌ \(errorMessage)")
            urlSchemeTask.didFailWithError(NSError(domain: "DiminaErrorDomain", code: 404, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            return
        }
        
        do {
            // Read file data
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // Set response headers
            let mimeType = mimeTypeForPath(path)
            let headers = ["Content-Type": mimeType, "Access-Control-Allow-Origin": "*"]
            let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: "UTF-8")
            
            // Return response and data
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
            
            print("✅ Resource loaded successfully: \(url.absoluteString)")
        } catch {
            print("❌ Resource loading failed: \(error.localizedDescription)")
            urlSchemeTask.didFailWithError(error)
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Cleanup operations when the task is stopped
        print("🛑 Stopping resource loading")
    }
    
    // Get MIME type based on file path
    private func mimeTypeForPath(_ path: String) -> String {
        let pathExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        
        switch pathExtension {
        case "html", "htm":
            return "text/html"
        case "css":
            return "text/css"
        case "js":
            return "application/javascript"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "svg":
            return "image/svg+xml"
        case "json":
            return "application/json"
        default:
            return "application/octet-stream"
        }
    }
}
