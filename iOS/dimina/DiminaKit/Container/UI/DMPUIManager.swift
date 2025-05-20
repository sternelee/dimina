import UIKit

public class DMPUIManager {
    public static let shared = DMPUIManager()

    private init() {}

    private var _statusBarHeight: CGFloat?

    private var _safeAreaInsets: UIEdgeInsets?

    private var _deviceDisplayInfo: [String: Any]?

    public func getStatusBarHeight() -> CGFloat {
        if let cachedHeight = _statusBarHeight {
            return cachedHeight
        }

        var statusBarHeight: CGFloat = 0

        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let statusBarManager = windowScene.statusBarManager
            {
                statusBarHeight = statusBarManager.statusBarFrame.height
            }
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.height
        }

        _statusBarHeight = statusBarHeight
        return statusBarHeight
    }

    public func getSafeAreaInsets() -> UIEdgeInsets {
        if let cachedInsets = _safeAreaInsets {
            return cachedInsets
        }

        var safeAreaInsets = UIEdgeInsets.zero

        if #available(iOS 15.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first
            {
                safeAreaInsets = window.safeAreaInsets
            }
        } else {
            safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
        }

        _safeAreaInsets = safeAreaInsets
        return safeAreaInsets
    }

    public func getDeviceDisplayInfo() -> [String: Any] {
        if let cachedInfo = _deviceDisplayInfo {
            return cachedInfo
        }

        let screenBounds = UIScreen.main.bounds
        let screenScale = UIScreen.main.scale

        let safeAreaInsets = getSafeAreaInsets()

        let windowWidth = screenBounds.width - (safeAreaInsets.left + safeAreaInsets.right)
        let windowHeight = screenBounds.height - (safeAreaInsets.top + safeAreaInsets.bottom)

        let statusBarHeight = getStatusBarHeight()

        let safeArea: [String: Any] = [
            "left": safeAreaInsets.left,
            "right": screenBounds.width - (safeAreaInsets.right),
            "top": safeAreaInsets.top,
            "bottom": screenBounds.height - (safeAreaInsets.bottom),
            "width": screenBounds.width - (safeAreaInsets.left) - (safeAreaInsets.right),
            "height": screenBounds.height - (safeAreaInsets.top) - (safeAreaInsets.bottom),
        ]

        let displayInfo: [String: Any] = [
            "pixelRatio": UIScreen.main.scale,
            "screenWidth": screenBounds.width,
            "screenHeight": screenBounds.height,
            "screenScale": screenScale,
            "windowWidth": windowWidth,
            "windowHeight": windowHeight,
            "statusBarHeight": statusBarHeight,
            "screenTop": statusBarHeight,
            "safeArea": safeArea,
        ]

        _deviceDisplayInfo = displayInfo
        return displayInfo
    }

    public func prepareUI() {
        _ = getStatusBarHeight()
        _ = getSafeAreaInsets()
        _ = getDeviceDisplayInfo()
    }

    public func clearCache() {
        _statusBarHeight = nil
        _safeAreaInsets = nil
        _deviceDisplayInfo = nil
    }
}
