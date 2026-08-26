import XCTest
@testable import dimina

final class DMPRemoteUpdateManagerTests: XCTestCase {
    func testActivatePendingUpdateSwitchesPackageAndPreservesPersistentFiles() async throws {
        let appId = "test-\(UUID().uuidString)"
        let appPath = DMPSandboxManager.appBundlePath(appId)
        let pendingPath = (DMPSandboxManager.sandboxPath() as NSString)
            .appendingPathComponent(".pending/\(appId)")
        defer { cleanup(appId: appId) }

        try write(config(appId: appId, versionCode: 1), to: (appPath as NSString).appendingPathComponent("config.json"))
        try write("old", to: (appPath as NSString).appendingPathComponent("main/logic.js"))
        try write("{}", to: (appPath as NSString).appendingPathComponent("main/app-config.json"))
        let userFile = (appPath as NSString).appendingPathComponent("store/saved.txt")
        try write("user", to: userFile)

        try write(config(appId: appId, versionCode: 2), to: (pendingPath as NSString).appendingPathComponent("config.json"))
        try write("new", to: (pendingPath as NSString).appendingPathComponent("main/logic.js"))
        try write("{}", to: (pendingPath as NSString).appendingPathComponent("main/app-config.json"))

        let activated = try await DMPRemoteUpdateManager.shared.activatePendingUpdate(appId: appId)

        XCTAssertTrue(activated)
        XCTAssertEqual(
            try String(contentsOfFile: (appPath as NSString).appendingPathComponent("main/logic.js")),
            "new"
        )
        XCTAssertEqual(try String(contentsOfFile: userFile), "user")
        XCTAssertFalse(FileManager.default.fileExists(atPath: pendingPath))
    }

    func testUninstallPreservesPersistentFilesAndRemovesPackageArtifacts() async throws {
        let appId = "test-\(UUID().uuidString)"
        let appPath = DMPSandboxManager.appBundlePath(appId)
        let pendingPath = (DMPSandboxManager.sandboxPath() as NSString)
            .appendingPathComponent(".pending/\(appId)")
        let remotePath = (DMPSandboxManager.sandboxPath() as NSString)
            .appendingPathComponent(".remote/\(appId)/2-test")
        let backupPath = (DMPSandboxManager.sandboxPath() as NSString)
            .appendingPathComponent(".backup/\(appId)/1")
        let downloadPath = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("dimina-updates/\(appId)/2.zip")
        defer { cleanup(appId: appId) }

        try write("logic", to: (appPath as NSString).appendingPathComponent("main/logic.js"))
        let userFile = (appPath as NSString).appendingPathComponent("store/saved.txt")
        try write("user", to: userFile)
        let tempFile = (appPath as NSString).appendingPathComponent("tmp/image.jpg")
        try write("temp", to: tempFile)
        try write("pending", to: (pendingPath as NSString).appendingPathComponent("main/logic.js"))
        try write("remote", to: (remotePath as NSString).appendingPathComponent("file"))
        try write("backup", to: (backupPath as NSString).appendingPathComponent("file"))
        try write("zip", to: downloadPath)

        try await DMPRemoteUpdateManager.shared.uninstallPackage(
            appId: appId,
            clearUserData: false
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: userFile))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFile))
        XCTAssertFalse(FileManager.default.fileExists(atPath: pendingPath))
        XCTAssertFalse(FileManager.default.fileExists(atPath: remotePath))
        XCTAssertFalse(FileManager.default.fileExists(atPath: backupPath))
        XCTAssertFalse(FileManager.default.fileExists(atPath: downloadPath))
    }

    func testUninstallCanClearPersistentFiles() async throws {
        let appId = "test-\(UUID().uuidString)"
        let appPath = DMPSandboxManager.appBundlePath(appId)
        defer { cleanup(appId: appId) }
        try write("user", to: (appPath as NSString).appendingPathComponent("store/saved.txt"))

        try await DMPRemoteUpdateManager.shared.uninstallPackage(
            appId: appId,
            clearUserData: true
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: appPath))
    }

    private func write(_ value: String, to path: String) throws {
        try FileManager.default.createDirectory(
            atPath: (path as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try value.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func config(appId: String, versionCode: Int) -> String {
        return "{\"appId\":\"\(appId)\",\"versionCode\":\(versionCode)}"
    }

    private func cleanup(appId: String) {
        DMPFileUtil.removeItem(at: DMPSandboxManager.appBundlePath(appId))
        DMPFileUtil.removeItem(
            at: (DMPSandboxManager.sandboxPath() as NSString).appendingPathComponent(".pending/\(appId)")
        )
        DMPFileUtil.removeItem(
            at: (DMPSandboxManager.sandboxPath() as NSString).appendingPathComponent(".remote/\(appId)")
        )
        DMPFileUtil.removeItem(
            at: (DMPSandboxManager.sandboxPath() as NSString).appendingPathComponent(".backup/\(appId)")
        )
        DMPFileUtil.removeItem(
            at: (NSTemporaryDirectory() as NSString).appendingPathComponent("dimina-updates/\(appId)")
        )
    }
}
