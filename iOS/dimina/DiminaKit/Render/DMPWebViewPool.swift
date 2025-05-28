//
//  DMPWebViewPool.swift
//  dimina
//
//  Created by Lehem on 2025/5/15.
//

import Foundation
import WebKit
import UIKit

/// WebView cache pool management class
/// Responsible for pre-creating, caching and reusing WebView instances to improve page opening speed
@MainActor
public class DMPWebViewPool {
    // MARK: - Singleton
    public static let shared = DMPWebViewPool()
    
    // MARK: - Properties
    private var availableWebViews: [DMPWebview] = []
    private var usedWebViews: Set<Int> = []
    private let maxPoolSize: Int = 3
    private let minPoolSize: Int = 1
    
    // Shared WKProcessPool instance - ensure creation on main thread
    internal static let sharedProcessPool: WKProcessPool = {
        // Ensure creation on main thread
        assert(Thread.isMainThread, "WKProcessPool must be created on main thread")
        let processPool = WKProcessPool()
        print("🔧 WebViewPool: Created shared WKProcessPool")
        return processPool
    }()
    
    // MARK: - Initialization
    private init() {
        setupNotifications()
        // Pre-warm during initialization - on main thread
        Task { @MainActor in
            await preloadWebViews()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        availableWebViews.removeAll()
        usedWebViews.removeAll()
        print("🧹 WebViewPool: Clear pool during deallocation")
    }
    
    // MARK: - Notification Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Add application termination notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Get a usable WebView instance
    /// - Parameters:
    ///   - delegate: WebView delegate
    ///   - appName: Application name
    ///   - appId: Application ID
    /// - Returns: Configured DMPWebview instance
    public func acquireWebView(delegate: DMPWebViewDelegate?, appName: String, appId: String) -> DMPWebview {
        print("🟦 WebViewPool: Requesting WebView, pool status - Available: \(availableWebViews.count), In use: \(usedWebViews.count)")
        
        let webview: DMPWebview
        
        if let reusableWebView = availableWebViews.popLast() {
            // Reuse existing WebView
            webview = reusableWebView
            
            webview.regenerateWebViewId()
            webview.setDelegate(delegate)
            webview.resetForReuse(appName: appName, appId: appId)
            
            print("🟢 WebViewPool: Reuse WebView (ID: \(webview.getWebViewId()))")
        } else {
            // Create new WebView
            webview = createNewWebView(delegate: delegate, appName: appName, appId: appId)
            webview.regenerateWebViewId()
            
            print("🟡 WebViewPool: Create new WebView (ID: \(webview.getWebViewId()))")
        }
        
        usedWebViews.insert(webview.getWebViewId())
        print("🟦 WebViewPool: WebView allocated, pool status - Available: \(availableWebViews.count), In use: \(usedWebViews.count)")
        
        // Asynchronous preload more WebViews - on main thread
        Task { @MainActor in
            await preloadWebViewsIfNeeded()
        }
        
        return webview
    }
    
    /// Release WebView instance back to pool
    /// - Parameter webview: WebView to release
    public func releaseWebView(_ webview: DMPWebview) {
        let webViewId = webview.getWebViewId()
        print("🟦 WebViewPool: Requesting to release WebView (ID: \(webViewId)), pool status - Available: \(availableWebViews.count), In use: \(usedWebViews.count)")
        
        // Check if it's in the used list
        if !usedWebViews.contains(webViewId) {
            print("⚠️ WebViewPool: Warning - Trying to release WebView that's not in use (ID: \(webViewId))")
        }
        
        usedWebViews.remove(webViewId)
        
        // Clean WebView state
        webview.prepareForReuse()
        
        // If pool is not full, return to pool
        if availableWebViews.count < maxPoolSize {
            availableWebViews.append(webview)
            print("🔵 WebViewPool: WebView returned to pool (ID: \(webViewId))")
        } else {
            // Pool is full, destroy WebView
            print("🔴 WebViewPool: Pool is full, destroy WebView (ID: \(webViewId))")
        }
        
        print("🟦 WebViewPool: WebView released, pool status - Available: \(availableWebViews.count), In use: \(usedWebViews.count)")
    }
    
    /// Warm up WebView pool
    public func warmUp() {
        Task { @MainActor in
            await preloadWebViews()
        }
    }
    
    /// Clear pool
    public func clearPool() {
        print("🧹 WebViewPool: Start clearing pool, current status - Available: \(availableWebViews.count), In use: \(usedWebViews.count)")
        
        // 1. Clean all available WebViews
        for webview in availableWebViews {
            cleanupWebView(webview)
        }
        availableWebViews.removeAll()
        
        // 2. Clean used WebViews (if any)
        // Note: Normally, there should be no used WebViews in the app exit case
        if !usedWebViews.isEmpty {
            print("⚠️ WebViewPool: Warning - Still \(usedWebViews.count) WebViews in use")
        }
        usedWebViews.removeAll()
        
        print("🧹 WebViewPool: Pool cleared")
    }
    
    /// Completely clean single WebView
    private func cleanupWebView(_ webview: DMPWebview) {
        print("🧹 WebViewPool: Clean WebView (ID: \(webview.getWebViewId()))")
        
        // Stop all network requests
        webview.getWebView().stopLoading()
        
        // Clean logger
        webview.logger?.cleanup()
        
        // Clean all message processors
        let userContentController = webview.getWebView().configuration.userContentController
        userContentController.removeAllUserScripts()
        
        // Clean all possible processors
        let allPossibleHandlers = ["invokeHandler", "publishHandler", "consoleLog", "consoleError", 
                                 "consoleWarn", "consoleInfo", "jsError", "networkError", "resourceError"]
        
        for handlerName in allPossibleHandlers {
            do {
                userContentController.removeScriptMessageHandler(forName: handlerName)
            } catch {
                // Ignore cleanup error
            }
        }
        
        // Clean custom JS bridges
        for handlerName in webview.jsBridgeCallbacks.keys {
            if !allPossibleHandlers.contains(handlerName) {
                do {
                    userContentController.removeScriptMessageHandler(forName: handlerName)
                } catch {
                    // Ignore cleanup error
                }
            }
        }
        webview.jsBridgeCallbacks.removeAll()
        
        // Navigate to blank page
        webview.getWebView().loadHTMLString("<html><body></body></html>", baseURL: nil)
        
        print("🧹 WebViewPool: WebView (ID: \(webview.getWebViewId())) cleaned")
    }
    
    /// Get pool status information
    public func getPoolStatus() -> (available: Int, used: Int) {
        return (available: availableWebViews.count, used: usedWebViews.count)
    }
    
    // MARK: - Private Methods
    
    /// Preload WebViews
    private func preloadWebViews() async {
        let currentCount = availableWebViews.count
        let neededCount = max(0, minPoolSize - currentCount) // Ensure not negative
        
        print("🔧 WebViewPool: Current pool has \(currentCount) WebViews, need to preload \(neededCount)")
        
        // Create only when needed
        guard neededCount > 0 else {
            print("🔧 WebViewPool: WebView pool count meets minimum requirement, no need to preload")
            return
        }
        
        for i in 0..<neededCount {
            // Double check, ensure not exceed max pool size
            if availableWebViews.count >= maxPoolSize {
                print("🔧 WebViewPool: Already reached max pool size, stop preloading")
                break
            }
            
            let webview = createNewWebView(delegate: nil, appName: "", appId: "")
            availableWebViews.append(webview)
            print("🔧 WebViewPool: Preload WebView \(i+1)/\(neededCount) (ID: \(webview.getWebViewId()))")
        }
        
        print("🔧 WebViewPool: Preload completed, current pool has \(availableWebViews.count) WebViews")
    }
    
    /// Preload more WebViews as needed
    private func preloadWebViewsIfNeeded() async {
        let currentCount = availableWebViews.count
        
        // Fix logic: Only preload when pool is empty or less than minimum count
        if currentCount < minPoolSize && currentCount < maxPoolSize {
            let webview = createNewWebView(delegate: nil, appName: "", appId: "")
            availableWebViews.append(webview)
            print("🔧 WebViewPool: Preload WebView as needed (ID: \(webview.getWebViewId())), current pool has \(availableWebViews.count) WebViews")
        } else {
            print("🔧 WebViewPool: Pool status good, no need to preload as needed (current: \(currentCount), minimum: \(minPoolSize), maximum: \(maxPoolSize))")
        }
    }
    
    /// Create new WebView instance - must be called on main thread
    private func createNewWebView(delegate: DMPWebViewDelegate?, appName: String, appId: String) -> DMPWebview {
        assert(Thread.isMainThread, "WebView must be created on main thread")
        
        let webview = DMPWebview(
            delegate: delegate,
            appName: appName,
            appId: appId,
            processPool: Self.sharedProcessPool
        )
        return webview
    }
    
    // MARK: - Notification Handlers
    
    @objc private func applicationDidEnterBackground() {
        // When app enters background, consider cleaning some WebViews to save memory
        print("🌙 WebViewPool: App entering background")
    }
    
    @objc private func applicationWillEnterForeground() {
        // When app is about to enter foreground, warm up WebView pool
        print("🌅 WebViewPool: App about to enter foreground, warming up pool")
        warmUp()
    }
    
    @objc private func applicationDidReceiveMemoryWarning() {
        // When receive memory warning, clean some WebViews
        print("⚠️ WebViewPool: Received memory warning, cleaning pool")
        
        // Only keep minimum number of WebViews
        let keepCount = min(minPoolSize, availableWebViews.count)
        availableWebViews = Array(availableWebViews.prefix(keepCount))
    }
    
    @objc private func applicationWillTerminate() {
        // When app is about to terminate, clean all WebViews
        print("🌙 WebViewPool: App about to terminate, cleaning all WebViews")
        clearPool()
    }
    
    /// Get shared process pool
    internal func getSharedProcessPool() -> WKProcessPool {
        return Self.sharedProcessPool
    }
}

// MARK: - WebView Pool Extensions
extension DMPWebview {
    /// Prepare WebView for reuse
    @MainActor
    fileprivate func prepareForReuse() {
        print("🧽 WebView (ID: \(getWebViewId())) start preparing for reuse")
        
        // Stop loading
        getWebView().stopLoading()
        
        // 1. Clean user scripts
        let userContentController = getWebView().configuration.userContentController
        userContentController.removeAllUserScripts()
        print("🧽 WebView (ID: \(getWebViewId())) cleaned user scripts")
        
        // 2. Critical fix: Clean all possible message handlers to avoid duplicate registration
        let allHandlerNames = [
            // JS bridge handlers
            "invokeHandler", "publishHandler",
            // Log handlers
            "consoleLog", "consoleError", "consoleWarn", "consoleInfo",
            // Error handlers
            "jsError", "networkError", "resourceError"
        ]
        
        // First clean known standard handlers
        for handlerName in allHandlerNames {
            do {
                userContentController.removeScriptMessageHandler(forName: handlerName)
                print("🧽 WebView (ID: \(getWebViewId())) cleaned handler: \(handlerName)")
            } catch {
                // If handler doesn't exist, ignore error
                print("🟡 WebView (ID: \(getWebViewId())) handler \(handlerName) doesn't exist, skip cleanup")
            }
        }
        
        // Then clean custom handlers recorded in jsBridgeCallbacks
        for handlerName in jsBridgeCallbacks.keys {
            if !allHandlerNames.contains(handlerName) {
                do {
                    userContentController.removeScriptMessageHandler(forName: handlerName)
                    print("🧽 WebView (ID: \(getWebViewId())) cleaned custom handler: \(handlerName)")
                } catch {
                    print("🟡 WebView (ID: \(getWebViewId())) custom handler cleanup failed: \(handlerName), error: \(error)")
                }
            }
        }
        
        // Clear callback records
        jsBridgeCallbacks.removeAll()
        print("🧽 WebView (ID: \(getWebViewId())) cleaned all JS bridge callbacks")
        
        // 3. Critical modification: Don't clean logger here to avoid double cleanup
        // Logger will be re-initialized in resetForReuse as needed
        if logger != nil {
            print("🧽 WebView (ID: \(getWebViewId())) keep existing logger to avoid double cleanup")
        }
        
        // 4. Clean web content to blank page (but not completely empty HTML)
        // Use minimized HTML to ensure WebView state is normal
        getWebView().loadHTMLString("""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body></body>
        </html>
        """, baseURL: nil)
        print("🧽 WebView (ID: \(getWebViewId())) cleaned web content")
        
        // 5. Reset loading state
        isLoading = true
        
        print("🧽 WebView (ID: \(getWebViewId())) prepared for reuse")
    }
    
    /// Reset WebView for new application
    @MainActor
    fileprivate func resetForReuse(appName: String, appId: String) {
        print("🔄 WebView (ID: \(getWebViewId())) start reset for app: \(appName)")
        
        // Update application information
        self.appName = appName
        
        // Critical fix: Check if logger already exists to avoid duplicate initialization causing double cleanup
        if self.logger == nil {
            // Re-initialize logger (only when no logger exists)
            self.logger = DMPWebViewLogger(webView: self.getWebView(), webViewId: self.getWebViewId())
            print("🔄 WebView (ID: \(getWebViewId())) re-initialized logger")
        } else {
            print("🔄 WebView (ID: \(getWebViewId())) logger already exists, skip re-initialization")
            // Ensure existing logger state is normal
            if self.logger != nil {
                // Verify if key handlers of logger still exist
                print("🔄 WebView (ID: \(getWebViewId())) verify existing logger state")
            }
        }
        
        // Critical fix: Don't clear page path and query parameters here
        // These values will be properly set in DMPPageController.configWebView()
        // Avoid empty path issues during resource loading
        print("🔄 WebView (ID: \(getWebViewId())) keep current page path: \(pagePath)")
        
        // Ensure WebView is in correct initial state
        self.isLoading = true
        
        print("🔄 WebView (ID: \(getWebViewId())) reset for app: \(appName)")
    }
} 
