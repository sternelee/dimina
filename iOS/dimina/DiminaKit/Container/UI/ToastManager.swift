//
//  ToastManager.swift
//  dimina
//
//  Created by DosLin on 2025/5/10.
//

import UIKit

/// Toast type enum to determine the icon to display
public enum ToastType {
    case success
    case error
    case loading
    case none
}

/// ToastManager is a singleton class that handles showing and hiding toast messages
public class ToastManager {
    
    // MARK: - Singleton
    
    /// Shared instance
    public static let shared = ToastManager()
    
    // MARK: - Properties
    
    /// Dedicated window for toast messages
    private var toastWindow: UIWindow?
    
    /// Toast container view
    private var containerView: UIView?
    
    /// Work item for dismissal
    private var dismissWorkItem: DispatchWorkItem?
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Public Methods
    
    /// Show a toast message with the specified parameters
    /// - Parameters:
    ///   - title: The message to display
    ///   - type: The type of toast (success, error, loading, none)
    ///   - duration: How long to display the toast in milliseconds (default: 1500)
    ///   - mask: Whether to show a mask behind the toast (default: false)
    public func showToast(title: String, type: ToastType = .success, duration: Int = 1500, mask: Bool = false) {
        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel any previous dismiss work
            self.dismissWorkItem?.cancel()
            self.dismissWorkItem = nil
            
            // Create a dedicated window for the toast
            self.createToastWindow()
            
            // Create toast content
            self.createToastContent(title: title, type: type, mask: mask)
            
            // Make the window visible
            self.toastWindow?.isHidden = false
            
            // Auto-dismiss if not loading type
            if type != .loading && duration > 0 {
                let durationInSeconds = Double(duration) / 1000.0
                
                // Create a new work item for dismissal
                let workItem = DispatchWorkItem { [weak self] in
                    self?.hideToast()
                }
                self.dismissWorkItem = workItem
                
                // Schedule dismissal
                DispatchQueue.main.asyncAfter(deadline: .now() + durationInSeconds, execute: workItem)
            }
        }
    }
    
    /// Hide the currently displayed toast
    public func hideToast() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel any pending dismiss work
            self.dismissWorkItem?.cancel()
            self.dismissWorkItem = nil
            
            // Animate out and remove toast window
            UIView.animate(withDuration: 0.3, animations: {
                self.toastWindow?.alpha = 0
            }) { _ in
                self.toastWindow?.isHidden = true
                self.toastWindow = nil
                self.containerView = nil
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Create a dedicated window for the toast
    private func createToastWindow() {
        // Create a new window
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.windowLevel = .alert + 1 // Above alerts
                window.backgroundColor = .clear
                window.isUserInteractionEnabled = false // Pass through touches
                self.toastWindow = window
            }
        } else {
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.windowLevel = .alert + 1 // Above alerts
            window.backgroundColor = .clear
            window.isUserInteractionEnabled = false // Pass through touches
            self.toastWindow = window
        }
        
        // Set up the root view controller (required for window)
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        self.toastWindow?.rootViewController = viewController
        self.toastWindow?.alpha = 0
    }
    
    /// Create the toast content
    private func createToastContent(title: String, type: ToastType, mask: Bool) {
        guard let window = self.toastWindow, let rootView = window.rootViewController?.view else { return }
        
        // Add mask if needed
        if mask {
            let maskView = UIView(frame: rootView.bounds)
            maskView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            rootView.addSubview(maskView)
        }
        
        // Create toast container
        let container = UIView()
        container.backgroundColor = UIColor(red: 76/255.0, green: 76/255.0, blue: 76/255.0, alpha: 1.0) // #4c4c4c color
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(container)
        self.containerView = container
        
        // Create content stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stackView)
        
        // Add icon based on type
        switch type {
        case .success:
            let imageView = UIImageView()
            imageView.image = self.createSuccessImage()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 40),
                imageView.heightAnchor.constraint(equalToConstant: 40)
            ])
            stackView.addArrangedSubview(imageView)
            
        case .error:
            let imageView = UIImageView()
            imageView.image = self.createErrorImage()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 40),
                imageView.heightAnchor.constraint(equalToConstant: 40)
            ])
            stackView.addArrangedSubview(imageView)
            
        case .loading:
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.color = .white
            activityIndicator.startAnimating()
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                activityIndicator.widthAnchor.constraint(equalToConstant: 40),
                activityIndicator.heightAnchor.constraint(equalToConstant: 40)
            ])
            stackView.addArrangedSubview(activityIndicator)
            
        case .none:
            break
        }
        
        // Add title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        stackView.addArrangedSubview(titleLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Stack view constraints
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            
            // Container constraints - make it a square
            container.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: rootView.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 120), // Fixed width for square
            container.heightAnchor.constraint(equalToConstant: 120) // Fixed height for square
        ])
        
        // Animate in
        UIView.animate(withDuration: 0.3) {
            window.alpha = 1
        }
    }
    
    /// Create a success checkmark image
    private func createSuccessImage() -> UIImage? {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw checkmark directly without circle background
        context.setStrokeColor(UIColor.white.cgColor) // White checkmark
        context.setLineWidth(3.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Draw a larger checkmark centered in the image
        context.move(to: CGPoint(x: 8, y: 20))
        context.addLine(to: CGPoint(x: 16, y: 28))
        context.addLine(to: CGPoint(x: 32, y: 12))
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /// Create an error X image
    private func createErrorImage() -> UIImage? {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw X directly without circle background
        context.setStrokeColor(UIColor.white.cgColor) // White X
        context.setLineWidth(3.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Draw a larger X centered in the image
        context.move(to: CGPoint(x: 10, y: 10))
        context.addLine(to: CGPoint(x: 30, y: 30))
        context.strokePath()
        
        context.move(to: CGPoint(x: 30, y: 10))
        context.addLine(to: CGPoint(x: 10, y: 30))
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
