import Testing
import UIKit
@testable import dimina

@Suite(.serialized)
@MainActor
struct DMPRetainedMiniProgramTests {
    private func makeApp(navigation hostNavigation: UINavigationController? = nil) async -> (DMPApp, DMPNavigator, UINavigationController) {
        let app = DMPApp(appConfig: DMPAppConfig(appName: "retention", appId: UUID().uuidString), appIndex: -1)
        app.service = DMPService(app: app)
        app.render = DMPRender(app: app)
        let navigator = app.getNavigator()!
        let navigation = hostNavigation ?? UINavigationController(rootViewController: UIViewController())
        navigator.setup(navigationController: navigation)
        _ = await navigator.launch(to: "pages/index/index", animated: false, showsLaunchLoading: false)
        await navigator.navigateTo(to: "pages/detail/index", animated: false)
        return (app, navigator, navigation)
    }

    @Test func restoresTheSamePagesAndRuntimeAcrossRepeatedHides() async throws {
        let (app, navigator, navigation) = await makeApp()
        defer { app.destroy() }
        let controllers = navigation.viewControllers
        let detail = try #require(controllers.last as? DMPPageController)
        let webView = detail.getWebView()
        let service = app.service
        let pageId = app.getCurrentWebViewId()

        for _ in 0..<2 {
            await navigator.hideMiniProgram()
            #expect(navigator.isRetainedInBackground)
            #expect(!navigator.isActiveNavigationOwner())
            #expect(navigation.viewControllers.count == 1)
            #expect(app.getCurrentWebViewId() == pageId)
            #expect(app.service === service)
            // A timer in the hidden app must not pop the host's stack.
            navigator.navigateBack(animated: false)
            #expect(navigation.viewControllers.count == 1)

            navigator.setup(navigationController: navigation)
            await app.launch(launchConfig: DMPLaunchConfig())
            #expect(!navigator.isRetainedInBackground)
            #expect(navigator.isActiveNavigationOwner())
            #expect(navigation.viewControllers.count == controllers.count)
            #expect(navigation.topViewController === detail)
            #expect(detail.getWebView() === webView)
            #expect(app.service === service)
        }
        await navigator.hideMiniProgram()
    }

    @Test func destroyingHiddenAppDoesNotTouchAnotherAppPresentation() async {
        let (first, firstNavigator, firstNavigation) = await makeApp()
        await firstNavigator.hideMiniProgram()
        let (second, secondNavigator, secondNavigation) = await makeApp(navigation: firstNavigation)
        defer { second.destroy() }
        let secondTop = secondNavigation.topViewController

        first.destroy()
        #expect(first.service == nil)
        #expect(!firstNavigator.isRetainedInBackground)
        #expect(firstNavigation.viewControllers.count == 3)
        #expect(secondNavigator.isActiveNavigationOwner())
        #expect(secondNavigation.topViewController === secondTop)
        await secondNavigator.hideMiniProgram()
    }
}
