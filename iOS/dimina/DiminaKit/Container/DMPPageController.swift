//
//  DMPPageController.swift
//  dimina
//
//  Created by Lehem on 2025/5/15.
//

import Foundation
import SwiftUI
import UIKit
import WebKit

/// DMPPageController is a specialized view controller for displaying mini-program pages
/// It directly integrates the functionality of both DMPPage and DMPViewController
public class DMPPageController: UIViewController {
    
    // Weak reference to the navigator
    private weak var navigator: DMPNavigator?
    
    // Page properties
    private let pagePath: String
    private let query: [String: Any]?
    private let appConfig: DMPAppConfig
    private weak var app: DMPApp?
    private let isRoot: Bool
    
    // WebView related
    private var webview: DMPWebview
    private var hostingController: UIHostingController<DMPWebViewContainer>?
    
    /// Initialization method
    /// - Parameters:
    ///   - pagePath: Page path
    ///   - query: Query parameters
    ///   - appConfig: App configuration
    ///   - app: App instance
    ///   - navigator: Navigator
    ///   - isRoot: Whether this is a root view controller
    public init(pagePath: String, query: [String: Any]?, appConfig: DMPAppConfig, app: DMPApp?, navigator: DMPNavigator?, isRoot: Bool = false) {
        self.pagePath = pagePath
        self.query = query
        self.appConfig = appConfig
        self.app = app
        self.navigator = navigator
        self.isRoot = isRoot
        
        // Create WebView
        self.webview = (app?.render!.createWebView(appName: appConfig.appName))!
        
        super.init(nibName: nil, bundle: nil)
        
        // Configure WebView
        configWebView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Configure WebView
    private func configWebView() {
        self.webview.setPagePath(pagePath: pagePath)
        if let query = query {
            self.webview.setQuery(query: query)
        }
        self.webview.loadPageFrame()
    }
    
    // View loaded
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = appConfig.appName
        
        // Create SwiftUI view container
        let webViewContainer = DMPWebViewContainer(webview: webview, isRoot: isRoot)
        hostingController = UIHostingController(rootView: webViewContainer)
        
        // Add child view controller
        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            hostingController.didMove(toParent: self)
        }
        
        // Set navigation bar style
        setupNavigationBar()
    }
    
    // View will appear
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    // View did appear
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // setupNavigationBar()
    }
    
    // Set navigation bar style
    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true        
        navigationItem.backButtonTitle = ""

        let navStyle = navigator?.getTopPageRecord()?.navStyle
        if let navStyle = navStyle {
            // 设置标题
            navigationItem.title = navStyle["navigationBarTitleText"] as? String
            navigationItem.backButtonTitle = navStyle["navigationBarTitleText"] as? String
            
            // 只有当navigationItem还没有自定义appearance时才设置默认样式
            // 这确保通过API设置的样式不会被覆盖
            if navigationItem.standardAppearance == nil, 
               let backgroundColor = navStyle["navigationBarBackgroundColor"] as? String,
               let textStyle = navStyle["navigationBarTextStyle"] as? String {

                if let navigator = navigator {
                    navigationItem.leftBarButtonItem = navigator.createBackButton(darkStyle: textStyle == "white")
                }

                let bgColor = DMPUtil.colorFromHexString(backgroundColor) ?? .white
                let textColor: UIColor = textStyle == "white" ? .white : .black
                
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = bgColor
                appearance.titleTextAttributes = [.foregroundColor: textColor]
                
                // 为当前控制器设置导航栏外观
                navigationItem.standardAppearance = appearance
                navigationItem.scrollEdgeAppearance = appearance
                navigationItem.compactAppearance = appearance
                
                if #available(iOS 15.0, *) {
                    navigationItem.compactScrollEdgeAppearance = appearance
                }
                
                // 设置导航栏按钮颜色
                navigationController?.navigationBar.tintColor = textColor
            }
        }

        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
    }
    
    // Back button tap event
    @objc private func backButtonTapped() {
        if let navigator = navigator {
            navigator.handleBackButtonTapped()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // Get WebView instance
    public func getWebView() -> DMPWebview {
        return webview
    }
    
    // Called when page is shown
    public func onShow() {
        // Add your logic here
    }
}

// SwiftUI view container for displaying WebView
public struct DMPWebViewContainer: View {
    @ObservedObject var webview: DMPWebview
    var isRoot: Bool = false
    
    public init(webview: DMPWebview, isRoot: Bool = false) {
        self.webview = webview
        self.isRoot = isRoot
    }
    
    public var body: some View {
        ZStack {
            DMPWebview.WebViewRepresentable(webview: webview)
            
            if webview.isLoading && isRoot {
                DMPLoadingView(appName: webview.appName)
                    .transition(.opacity)
            }
        }
        .onChange(of: webview.isLoading) { newValue in
            // WebView loading state changed
        }
    }
} 
