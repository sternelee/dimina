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
    private let showsLaunchLoading: Bool

    // WebView related
    private var webview: DMPWebview
    private var hostingController: UIHostingController<DMPWebViewContainer>?
    private var customNavigationBar: UIView?
    private var customNavigationContentView: UIView?
    private var customNavigationTitleLabel: UILabel?
    private var customNavigationBackButton: UIButton?
    private var webViewTopToNavigationConstraint: NSLayoutConstraint?
    private var webViewTopToViewConstraint: NSLayoutConstraint?
    private var loadingView: UIView?
    private weak var loadingParentController: UIViewController?

    // State
    private var isWebViewDestroyed = false
    private var hasStartedLoading = false
    private var hasShownLaunchLoading = false

    /// Initialization method
    /// - Parameters:
    ///   - pagePath: Page path
    ///   - query: Query parameters
    ///   - appConfig: App configuration
    ///   - app: App instance
    ///   - navigator: Navigator
    ///   - isRoot: Whether this is a root view controller
    ///   - showsLaunchLoading: Whether to show the app launch loading overlay
    public init(
        pagePath: String, query: [String: Any]?, appConfig: DMPAppConfig, app: DMPApp?,
        navigator: DMPNavigator?, isRoot: Bool = false, showsLaunchLoading: Bool = false
    ) {
        self.pagePath = pagePath
        self.query = query
        self.appConfig = appConfig
        self.app = app
        self.navigator = navigator
        self.isRoot = isRoot
        self.showsLaunchLoading = showsLaunchLoading

        // Create WebView
        self.webview = (app?.render!.createWebView(appName: appConfig.appName))!

        super.init(nibName: nil, bundle: nil)

        // Configure WebView - Configure immediately to ensure page path is set correctly
        configWebView()
        observeLoadingState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Configure WebView
    private func configWebView() {        
        // Set page path and query parameters
        self.webview.setPagePath(pagePath: pagePath)
        if let query = query {
            self.webview.setQuery(query: query)
        }
        
        print("🔧 DMPPageController: WebView (ID: \(webview.getWebViewId())) configuration completed, current page path: \(webview.getPagePath())")
        
        app?.render?.setupJSBridge(webViewId: webview.getWebViewId())

    }

    // View loaded
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupCustomNavigationBar()

        // Create SwiftUI view container
        let webViewContainer = DMPWebViewContainer(webview: webview, isRoot: isRoot)
        hostingController = UIHostingController(rootView: webViewContainer)

        // Add child view controller
        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            webViewTopToNavigationConstraint = hostingController.view.topAnchor.constraint(
                equalTo: customNavigationBar?.bottomAnchor ?? view.topAnchor
            )
            webViewTopToViewConstraint = hostingController.view.topAnchor.constraint(equalTo: view.topAnchor)
            NSLayoutConstraint.activate([
                webViewTopToNavigationConstraint!,
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
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupNavigationBar()
        showPageLoadingIfNeeded()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let customNavigationBar = customNavigationBar, !customNavigationBar.isHidden {
            view.bringSubviewToFront(customNavigationBar)
        }
        loadingView?.superview?.bringSubviewToFront(loadingView!)
    }

    // View did appear
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startLoadingIfNeeded()
    }

    private func startLoadingIfNeeded() {
        guard !hasStartedLoading, !isWebViewDestroyed else {
            return
        }

        hasStartedLoading = true
        showPageLoadingIfNeeded()
        webview.poolState = .loading
        webview.loadPageFrame()
    }

    public func preparePageLoading(in parentController: UIViewController) {
        guard showsLaunchLoading else {
            return
        }

        installPageLoading(in: parentController, isVisible: false)
    }

    private func observeLoadingState() {
        webview.onLoadingStateChanged = { [weak self] isLoading in
            let updateLoading = {
                if isLoading {
                    self?.showPageLoadingIfNeeded()
                } else {
                    self?.hidePageLoading()
                }
            }

            if Thread.isMainThread {
                updateLoading()
            } else {
                DispatchQueue.main.async {
                    updateLoading()
                }
            }
        }
    }

    private func showPageLoadingIfNeeded() {
        guard showsLaunchLoading, !hasShownLaunchLoading else {
            return
        }

        hasShownLaunchLoading = true
        showPageLoading()
    }

    private func showPageLoading() {
        let parentController = loadingParentController ?? navigationController ?? self
        installPageLoading(in: parentController, isVisible: true)
    }

    private func installPageLoading(in parentController: UIViewController, isVisible: Bool) {
        let parentView = parentController.view!

        if let loadingView = self.loadingView {
            loadingView.superview?.bringSubviewToFront(loadingView)
            UIView.performWithoutAnimation {
                loadingView.alpha = isVisible ? 1 : 0
                loadingView.isUserInteractionEnabled = isVisible
                parentView.layoutIfNeeded()
            }
            return
        }

        let loadingView = makePageLoadingView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.alpha = isVisible ? 1 : 0
        loadingView.isUserInteractionEnabled = isVisible

        parentView.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: parentView.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        ])
        parentView.bringSubviewToFront(loadingView)
        UIView.performWithoutAnimation {
            parentView.layoutIfNeeded()
        }

        self.loadingView = loadingView
        self.loadingParentController = parentController
    }

    private func setupCustomNavigationBar() {
        let navigationBar = UIView()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let backButton = UIButton(type: .custom)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(customBackButtonTapped), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail

        view.addSubview(navigationBar)
        navigationBar.addSubview(contentView)
        contentView.addSubview(backButton)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
        ])

        customNavigationBar = navigationBar
        customNavigationContentView = contentView
        customNavigationBackButton = backButton
        customNavigationTitleLabel = titleLabel
    }

    private func makePageLoadingView() -> UIView {
        let container = UIView()
        container.backgroundColor = .white

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIView()
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let ringView = UIView()
        ringView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        ringView.layer.borderWidth = 1
        ringView.layer.cornerRadius = 30
        ringView.translatesAutoresizingMaskIntoConstraints = false

        let appIconView = UIView()
        appIconView.backgroundColor = loadingIconColor(for: webview.appName)
        appIconView.layer.cornerRadius = 20
        appIconView.translatesAutoresizingMaskIntoConstraints = false

        let rotorView = UIView()
        rotorView.translatesAutoresizingMaskIntoConstraints = false

        let dotView = UIView()
        dotView.backgroundColor = .systemGreen
        dotView.layer.cornerRadius = 3
        dotView.translatesAutoresizingMaskIntoConstraints = false

        let initialLabel = UILabel()
        initialLabel.text = String(webview.appName.prefix(1))
        initialLabel.textColor = .white
        initialLabel.font = .systemFont(ofSize: 16, weight: .bold)
        initialLabel.textAlignment = .center
        initialLabel.translatesAutoresizingMaskIntoConstraints = false

        let appNameLabel = UILabel()
        appNameLabel.text = webview.appName
        appNameLabel.textColor = .label
        appNameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        appNameLabel.textAlignment = .center

        container.addSubview(stackView)
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(appNameLabel)

        iconView.addSubview(ringView)
        iconView.addSubview(appIconView)
        iconView.addSubview(rotorView)
        rotorView.addSubview(dotView)
        appIconView.addSubview(initialLabel)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),

            ringView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            ringView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            ringView.widthAnchor.constraint(equalToConstant: 60),
            ringView.heightAnchor.constraint(equalToConstant: 60),

            appIconView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            appIconView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            appIconView.widthAnchor.constraint(equalToConstant: 40),
            appIconView.heightAnchor.constraint(equalToConstant: 40),

            rotorView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            rotorView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            rotorView.widthAnchor.constraint(equalToConstant: 60),
            rotorView.heightAnchor.constraint(equalToConstant: 60),

            dotView.centerXAnchor.constraint(equalTo: rotorView.centerXAnchor),
            dotView.centerYAnchor.constraint(equalTo: rotorView.topAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 6),
            dotView.heightAnchor.constraint(equalToConstant: 6),

            initialLabel.centerXAnchor.constraint(equalTo: appIconView.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: appIconView.centerYAnchor),
        ])

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1.2
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        rotorView.layer.add(rotation, forKey: "loading.rotation")

        return container
    }

    private func loadingIconColor(for name: String) -> UIColor {
        guard !name.isEmpty else {
            return UIColor(red: 33 / 255, green: 150 / 255, blue: 243 / 255, alpha: 1)
        }

        var hash: Int32 = 0
        for scalar in name.unicodeScalars {
            hash = 31 &* hash &+ Int32(scalar.value)
        }

        let hue = CGFloat(abs(hash % 360)) / 360.0
        let saturation = CGFloat(0.7 + Float(hash % 3000) / 10000.0)
        let brightness = CGFloat(0.8 + Float(hash % 2000) / 10000.0)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }

    private func hidePageLoading() {
        guard let loadingView = loadingView else {
            return
        }

        loadingView.removeFromSuperview()

        self.loadingView = nil
        self.loadingParentController = nil

        setupNavigationBar()
    }

    public func updateNavigationTitle(_ title: String) {
        let nextTitle = title.isEmpty ? appConfig.appName : title
        customNavigationTitleLabel?.text = nextTitle
        navigationItem.title = nextTitle
    }

    public func updateNavigationColor(backgroundColor: UIColor, textColor: UIColor, darkStyle: Bool) {
        customNavigationBar?.backgroundColor = backgroundColor
        customNavigationTitleLabel?.textColor = textColor
        updateCustomBackButton(darkStyle: darkStyle)
    }

    private func updateCustomBackButton(darkStyle: Bool) {
        guard let backButton = customNavigationBackButton else {
            return
        }

        if let bundle = DMPResourceManager.assetsBundle {
            let imageName = darkStyle ? "arrow-back-dark" : "arrow-back-light"
            if let image = UIImage(named: imageName, in: bundle, compatibleWith: nil) {
                backButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
                backButton.setTitle(nil, for: .normal)
                return
            }
        }

        backButton.setImage(nil, for: .normal)
        backButton.setTitle("back", for: .normal)
        backButton.setTitleColor(darkStyle ? .white : .black, for: .normal)
    }

    @objc private func customBackButtonTapped() {
        navigator?.handleBackButtonTapped()
    }

    // Set navigation bar style
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.hidesBackButton = true
        navigationItem.backButtonTitle = ""

        let navStyle = navigator?.getTopPageRecord()?.navStyle
        let darkStyle = (navStyle?["navigationBarTextStyle"] as? String) == "white"
        var title = appConfig.appName
        var backgroundColor = UIColor.white
        var textColor = darkStyle ? UIColor.white : UIColor.black
        var isCustomNavigationStyle = false

        if let navStyle = navStyle {
            if let navTitle = navStyle["navigationBarTitleText"] as? String, !navTitle.isEmpty {
                title = navTitle
            }

            if let navigationStyle = navStyle["navigationStyle"] as? String {
                isCustomNavigationStyle = navigationStyle == "custom"
            }

            if let navBackgroundColor = navStyle["navigationBarBackgroundColor"] as? String {
                backgroundColor = DMPUtil.colorFromHexString(navBackgroundColor) ?? .white
            }

            if let navTextStyle = navStyle["navigationBarTextStyle"] as? String {
                textColor = navTextStyle == "white" ? .white : .black
            }

            // Only set default style if navigationItem has not been customized
            // This ensures that styles set via API are not overridden
            if navigationItem.standardAppearance == nil,
                let backgroundColor = navStyle["navigationBarBackgroundColor"] as? String,
                let textStyle = navStyle["navigationBarTextStyle"] as? String
            {

                let darkStyle = textStyle == "white"
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

        updateNavigationTitle(title)
        updateNavigationColor(backgroundColor: backgroundColor, textColor: textColor, darkStyle: darkStyle)

        customNavigationBar?.isHidden = isCustomNavigationStyle
        webViewTopToNavigationConstraint?.isActive = !isCustomNavigationStyle
        webViewTopToViewConstraint?.isActive = isCustomNavigationStyle

        if !isCustomNavigationStyle, let customNavigationBar = customNavigationBar {
            view.bringSubviewToFront(customNavigationBar)
        }
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
        hidePageLoading()
        
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
        webview.onLoadingStateChanged = nil
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
        }
    }
}
