//
//  DMPFileUtil.swift
//  dimina
//
//  Created by Lehem on 2025/4/17.
//

import CommonCrypto
import Foundation
import ZIPFoundation

public class DMPFileUtil {

    private final class VirtualFilePrefixState: @unchecked Sendable {
        private let lock = NSLock()
        private var scheme = "difile"

        func readScheme() -> String {
            lock.lock()
            defer { lock.unlock() }
            return scheme
        }

        func updateScheme(_ value: String) {
            lock.lock()
            scheme = value
            lock.unlock()
        }
    }

    private static let virtualFilePrefixState = VirtualFilePrefixState()
    private static let reservedVirtualFileSchemes: Set<String> = [
        "about", "blob", "content", "data", "dimina", "file", "ftp", "http", "https",
        "internal", "javascript", "resource", "ws", "wss",
    ]

    public static var DMPFileURLScheme: String {
        virtualFilePrefixState.readScheme()
    }

    public static var virtualFilePrefix: String {
        "\(DMPFileURLScheme)://"
    }

    static func normalizedVirtualFilePrefix(_ prefix: String) -> String? {
        let normalized = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.range(
            of: "^[a-z][a-z0-9+.-]*://$",
            options: .regularExpression
        ) != nil,
              !reservedVirtualFileSchemes.contains(String(normalized.dropLast(3))) else {
            return nil
        }
        return normalized
    }

    @discardableResult
    static func configureVirtualFilePrefix(_ prefix: String) -> Bool {
        guard let normalized = normalizedVirtualFilePrefix(prefix) else { return false }
        virtualFilePrefixState.updateScheme(String(normalized.dropLast(3)))
        return true
    }

    private init() {}

    @discardableResult
    public static func unzipFile(
        at zipPath: String, to destinationPath: String, overwrite: Bool = true
    ) -> Bool {
        do {
            if overwrite && FileManager.default.fileExists(atPath: destinationPath) {
                try FileManager.default.removeItem(atPath: destinationPath)
            }

            try FileManager.default.createDirectory(
                atPath: destinationPath, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.unzipItem(
                at: URL(fileURLWithPath: zipPath),
                to: URL(fileURLWithPath: destinationPath)
            )
            DMPLogger.debug("成功解压文件: \(zipPath) 到 \(destinationPath)")
            return true
        } catch {
            DMPLogger.debug("解压文件过程中发生错误: \(error)")
            return false
        }
    }

    @discardableResult
    public static func copyContents(
        from sourcePath: String, to destinationPath: String, excludeItems: [String] = []
    ) -> Bool {
        do {
            // 确保目标目录存在
            try FileManager.default.createDirectory(
                atPath: destinationPath, withIntermediateDirectories: true, attributes: nil)

            // 获取源目录下的所有内容
            let contents = try FileManager.default.contentsOfDirectory(atPath: sourcePath)

            // 遍历复制文件
            for item in contents {
                // 跳过需要排除的文件
                if excludeItems.contains(item) {
                    continue
                }

                let sourceItemPath = (sourcePath as NSString).appendingPathComponent(item)
                let destinationItemPath = (destinationPath as NSString).appendingPathComponent(item)

                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: sourceItemPath, isDirectory: &isDir) {
                    if isDir.boolValue {
                        // 如果是目录，递归复制
                        try FileManager.default.createDirectory(
                            atPath: destinationItemPath, withIntermediateDirectories: true,
                            attributes: nil)
                        if !copyContents(from: sourceItemPath, to: destinationItemPath) {
                            return false
                        }
                    } else {
                        // 如果是文件，直接复制
                        if FileManager.default.fileExists(atPath: destinationItemPath) {
                            try FileManager.default.removeItem(atPath: destinationItemPath)
                        }
                        try FileManager.default.copyItem(
                            atPath: sourceItemPath, toPath: destinationItemPath)
                    }
                }
            }

            return true
        } catch {
            DMPLogger.debug("复制文件过程中发生错误: \(error)")
            return false
        }
    }

    static func replaceDirectory(
        from sourcePath: String,
        to destinationPath: String,
        backupPath: String,
        preserving relativePaths: [String]
    ) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            atPath: (backupPath as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true,
            attributes: nil
        )
        if fileManager.fileExists(atPath: backupPath) {
            try fileManager.removeItem(atPath: backupPath)
        }

        do {
            if fileManager.fileExists(atPath: destinationPath) {
                try fileManager.moveItem(atPath: destinationPath, toPath: backupPath)
            }
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)

            if fileManager.fileExists(atPath: backupPath) {
                for relativePath in relativePaths {
                    let oldPath = (backupPath as NSString).appendingPathComponent(relativePath)
                    guard fileManager.fileExists(atPath: oldPath) else { continue }
                    let newPath = (destinationPath as NSString).appendingPathComponent(relativePath)
                    if fileManager.fileExists(atPath: newPath) {
                        try fileManager.removeItem(atPath: newPath)
                    }
                    try fileManager.createDirectory(
                        atPath: (newPath as NSString).deletingLastPathComponent,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    try fileManager.copyItem(atPath: oldPath, toPath: newPath)
                }
                try fileManager.removeItem(atPath: backupPath)
            }
        } catch {
            if fileManager.fileExists(atPath: destinationPath) {
                try? fileManager.removeItem(atPath: destinationPath)
            }
            if fileManager.fileExists(atPath: backupPath) {
                try? fileManager.moveItem(atPath: backupPath, toPath: destinationPath)
            }
            throw error
        }
    }

    @discardableResult
    public static func removeItem(at path: String) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
                return true
            }
            return false
        } catch {
            DMPLogger.debug("删除文件失败: \(error)")
            return false
        }
    }

    @discardableResult
    public static func createDirectory(at path: String) -> Bool {
        do {
            try FileManager.default.createDirectory(
                atPath: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            DMPLogger.debug("创建目录失败: \(error)")
            return false
        }
    }

    public static func fileExists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    public static func readJsonFile(at path: String) -> String {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return "{}"
        }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    public static func loadJSONFromFile(filePath: String) -> [String: Any]? {
        guard
            let fileURL = URL(fileURLWithPath: filePath).isFileURL
                ? URL(fileURLWithPath: filePath) : nil
        else {
            DMPLogger.debug("无效的文件路径")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            DMPLogger.debug("加载 JSON 文件失败: \(error)")
            return nil
        }
    }

    public static func vPathFromSandboxPath(sandboxPath: String, appId: String) -> String {
        let storeDirectory: String = DMPSandboxManager.appStoreResourceDirectoryPath(appId: appId)
        if sandboxPath.hasPrefix(storeDirectory) {
            let relativePath: String = sandboxPath.replacingOccurrences(of: storeDirectory, with: "")
            return "\(DMPFileURLScheme)://usr\(relativePath)"
        }
        let resourceDirectory: String = DMPSandboxManager.appTmpResourceDirectoryPath(appId: appId)
        let relativePath: String = sandboxPath
            .replacingOccurrences(of: resourceDirectory, with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let vPath: String = "\(DMPFileURLScheme)://\(relativePath)"
        return vPath
    }

    public static func sandboxPathFromVPath(from vPath: String, appId: String) -> String? {
        guard let components: URLComponents = URLComponents(string: vPath),
              components.scheme?.lowercased() == DMPFileURLScheme,
              components.user == nil,
              components.password == nil else {
            return nil
        }

        let host = components.host ?? ""
        let path: String = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if host == "usr" {
            return confinedPath(
                rootPath: DMPSandboxManager.appStoreResourceDirectoryPath(appId: appId),
                relativePath: path
            )
        }
        let resourceDirectory: String = DMPSandboxManager.appTmpResourceDirectoryPath(appId: appId)
        let relativePath = ([host, path].filter { !$0.isEmpty }).joined(separator: "/")
        return confinedPath(rootPath: resourceDirectory, relativePath: relativePath)
    }

    /// Resolve a native-component media source without allowing it to escape
    /// the current mini program's package or user/temp directories.
    public static func appAccessiblePath(from rawPath: String, appId: String) -> String? {
        guard !rawPath.isEmpty else { return nil }
        if rawPath.lowercased().hasPrefix("\(DMPFileURLScheme)://") {
            return sandboxPathFromVPath(from: rawPath, appId: appId)
        }

        var localPath = rawPath
        if let components = URLComponents(string: rawPath), components.scheme != nil {
            guard components.scheme?.lowercased() == "file",
                  components.user == nil,
                  components.password == nil,
                  components.host == nil || components.host?.isEmpty == true,
                  let fileURL = components.url else {
                return nil
            }
            localPath = fileURL.path
        }

        let packageRoot = DMPSandboxManager.appBundlePath(appId)
        let appPathPrefix = "/\(appId)/"
        if localPath.hasPrefix(appPathPrefix) {
            return confinedPath(
                rootPath: packageRoot,
                relativePath: String(localPath.dropFirst(appPathPrefix.count))
            )
        }
        if !localPath.hasPrefix("/") {
            guard !localPath.contains("\\"),
                  !localPath.contains("\0"),
                  !localPath.split(separator: "/", omittingEmptySubsequences: false).contains("..") else {
                return nil
            }
            let direct = confinedPath(rootPath: packageRoot, relativePath: localPath)
            if let direct, FileManager.default.fileExists(atPath: direct) {
                return direct
            }
            return confinedPath(rootPath: packageRoot, relativePath: "main/\(localPath)")
        }
        return confinedAbsolutePath(localPath, allowedRoots: [packageRoot])
    }

    public static func confinedAbsolutePath(_ path: String, allowedRoots: [String]) -> String? {
        guard path.hasPrefix("/"), !path.contains("\0") else { return nil }
        let target = URL(fileURLWithPath: path)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
        for rootPath in allowedRoots where !rootPath.isEmpty {
            let root = URL(fileURLWithPath: rootPath, isDirectory: true)
                .standardizedFileURL
                .resolvingSymlinksInPath()
                .path
            if target == root || target.hasPrefix(root + "/") {
                return target
            }
        }
        return nil
    }

    /// Resolve a relative path while guaranteeing that the final filesystem
    /// location remains under `rootPath`, including after dot-segment and
    /// symlink resolution.
    public static func confinedPath(rootPath: String, relativePath: String) -> String? {
        guard !rootPath.isEmpty,
              !relativePath.contains("\0") else {
            return nil
        }

        let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let trimmedPath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let targetURL = rootURL
            .appendingPathComponent(trimmedPath)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let root = rootURL.path
        let target = targetURL.path
        guard target == root || target.hasPrefix(root + "/") else {
            return nil
        }
        return target
    }

}

// MARK: - String MD5 扩展
extension String {
    var dmp_sha256: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        _ = data.withUnsafeBytes { buffer in
            CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &digest)
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
