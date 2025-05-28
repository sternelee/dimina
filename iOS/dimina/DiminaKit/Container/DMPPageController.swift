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

    // State
    private var isWebViewDestroyed = false

    /// Initialization method
    /// - Parameters:
    ///   - pagePath: Page path
    ///   - query: Query parameters
    ///   - appConfig: App configuration
    ///   - app: App instance
    ///   - navigator: Navigator
    ///   - isRoot: Whether this is a root view controller
    public init(
        pagePath: String, query: [String: Any]?, appConfig: DMPAppConfig, app: DMPApp?,
        navigator: DMPNavigator?, isRoot: Bool = false
    ) {
        self.pagePath = pagePath
        self.query = query
        self.appConfig = appConfig
        self.app = app
        self.navigator = navigator
        self.isRoot = isRoot

        // Create WebView
        self.webview = (app?.render!.createWebView(appName: appConfig.appName))!

        super.init(nibName: nil, bundle: nil)

        // Configure WebView - Configure immediately to ensure page path is set correctly
        configWebView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Configure WebView
    private func configWebView() {
        print("�� DMPPageController: Configure WebView (ID: \(webview.getWebViewId())) page path: \(pagePath)")
        
        // Set page path and query parameters
        self.webview.setPagePath(pagePath: pagePath)
        if let query = query {
            self.webview.setQuery(query: query)
        }
        
        print("🔧 DMPPageController: WebView (ID: \(webview.getWebViewId())) configuration completed, current page path: \(webview.getPagePath())")
        
        // Load page frame
        webview.loadPageFrame()
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
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
            // Set title
            navigationItem.title = navStyle["navigationBarTitleText"] as? String
            navigationItem.backButtonTitle = navStyle["navigationBarTitleText"] as? String

            // Only set default style if navigationItem has not been customized
            // This ensures that styles set via API are not overridden
            if navigationItem.standardAppearance == nil,
                let backgroundColor = navStyle["navigationBarBackgroundColor"] as? String,
                let textStyle = navStyle["navigationBarTextStyle"] as? String
            {

                let darkStyle = textStyle == "white"

                if let navigator = navigator {
                    navigationItem.leftBarButtonItem = navigator.createBackButton(
                        darkStyle: darkStyle)
                }

                let bgColor = DMPUtil.colorFromHexString(backgroundColor) ?? .white
                let textColor: UIColor = darkStyle ? .white : .black

                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = bgColor
                appearance.titleTextAttributes = [.foregroundColor: textColor]

                // Set navigation bar appearance for the current controller
                navigationItem.standardAppearance = appearance
                navigationItem.scrollEdgeAppearance = appearance
                navigationItem.compactAppearance = appearance

                if #available(iOS 15.0, *) {
                    navigationItem.compactScrollEdgeAppearance = appearance
                }

                // Set navigation bar button color
                navigationController?.navigationBar.tintColor = textColor

                DMPUIManager.updateWindowStyle(isDarkTheme: darkStyle)
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
    
    // MARK: - Lifecycle Methods
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Notify lifecycle management when page completely disappears
        if isMovingFromParent {
            // Page is removed from navigation stack
            destroyWebView()
        }
    }
    
    // Destroy WebView
    private func destroyWebView() {
        // Add state check to prevent duplicate destruction
        guard !isWebViewDestroyed else {
            print("🟡 DMPPageController: WebView (ID: \(webview.getWebViewId())) has already been destroyed, skipping duplicate operation")
            return
        }
        
        print("🗑️ DMPPageController: Destroy WebView (ID: \(webview.getWebViewId()))")
        isWebViewDestroyed = true
        
        // Notify page unload
        if let app = app {
            let msg = DMPMap([
                "type": "pageUnload",
                "body": [
                    "bridgeId": webview.getWebViewId()
                ]
            ])
            DMPChannelProxy.containerToService(msg: msg, app: app)
        }
        
        // Release WebView back to pool
        app?.render?.releaseWebView(webview)
    }
    
    // Manual destroy method (for external calls)
    public func destroy() {
        destroyWebView()
    }
    
    deinit {
        print("🗑️ DMPPageController: deinit (WebView ID: \(webview.getWebViewId()))")
        // Ensure WebView is correctly released
        destroyWebView()
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
