// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Dimina",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Dimina",
            targets: ["Dimina"]
        ),
        .library(name: "DiminaMapAMap", targets: ["DiminaMapAMap"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", exact: "5.12.0"),
        .package(url: "https://github.com/Tencent/MMKV.git", exact: "2.4.2"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20"),
    ],
    targets: [
        .target(
            name: "Dimina",
            dependencies: [
                "Alamofire",
                "MMKV",
                "ZIPFoundation",
            ],
            path: "iOS/dimina",
            exclude: [
                "ContentView.swift",
                "diminaApp.swift",
                "Assets.xcassets",
                "Preview Content",
                // Compiled by the optional DiminaMapAMap target, not the core SDK.
                "DiminaKit/Map/DMPAMapProvider.swift",
            ],
            sources: [
                "DiminaKit"
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/JsApp.bundle"),
                .copy("Resources/JsSdk.bundle"),
            ]
        ),
        .binaryTarget(
            name: "MAMapKit",
            url: "https://github.com/didi/dimina/releases/download/v1.7.5/MAMapKit-11.2.100.xcframework.zip",
            checksum: "bd991fb5990937b03e2d2b327ca90c7e4b6dab23f821195ce41284b27ae5eb1c"
        ),
        .binaryTarget(
            name: "AMapFoundationKit",
            url: "https://github.com/didi/dimina/releases/download/v1.7.5/AMapFoundationKit-1.9.1.xcframework.zip",
            checksum: "10103d8e64c8521f9a200164c1dbef75c9df988111c37758bcc18578fdebfca5"
        ),
        .target(
            name: "DiminaMapAMap",
            dependencies: ["Dimina", "MAMapKit", "AMapFoundationKit"],
            path: "iOS/dimina/DiminaKit/Map",
            exclude: ["DMPMapProvider.swift", "DMPNativeMapHost.swift"],
            sources: ["DMPAMapProvider.swift"],
            linkerSettings: [
                .linkedFramework("QuartzCore"), .linkedFramework("CoreLocation"),
                .linkedFramework("SystemConfiguration"), .linkedFramework("CoreTelephony"),
                .linkedFramework("Security"), .linkedFramework("OpenGLES"),
                .linkedFramework("CoreText"), .linkedFramework("CoreGraphics"),
                .linkedFramework("GLKit"), .linkedLibrary("z"), .linkedLibrary("c++"),
            ]
        )
    ],
    // Keep SwiftPM consumers aligned with the checked-in Xcode target until the SDK's shared
    // mutable registries have completed a strict-concurrency migration.
    swiftLanguageModes: [.v5]
)
