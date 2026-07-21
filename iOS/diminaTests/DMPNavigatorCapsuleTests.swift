//
//  DMPNavigatorCapsuleTests.swift
//  diminaTests
//

import UIKit
import XCTest
@testable import dimina

@MainActor
final class DMPNavigatorCapsuleTests: XCTestCase {

    func testSetupInstallsOneContainerOwnedCapsule() {
        let navigationController = UINavigationController()
        navigationController.loadViewIfNeeded()
        let navigator = DMPNavigator()

        navigator.setup(navigationController: navigationController)
        navigator.setCapsuleVisible(true)

        XCTAssertEqual(capsules(in: navigationController.view).count, 1)
        XCTAssertFalse(capsules(in: navigationController.view)[0].isHidden)
    }

    func testRepeatedSetupReplacesRatherThanDuplicatesCapsule() {
        let navigationController = UINavigationController()
        navigationController.loadViewIfNeeded()
        let navigator = DMPNavigator()

        navigator.setup(navigationController: navigationController)
        navigator.setup(navigationController: navigationController)

        XCTAssertEqual(capsules(in: navigationController.view).count, 1)
    }

    private func capsules(in view: UIView) -> [UIView] {
        let current = view.accessibilityIdentifier == "dimina.navigation.capsule" ? [view] : []
        return current + view.subviews.flatMap(capsules(in:))
    }
}
