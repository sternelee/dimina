import Foundation
import Testing
@testable import dimina

struct DMPBundleAppConfigTests {
    @Test func declaredMainPagesDoNotRequireModuleMetadata() throws {
        for modules in [nil, [:], ["example/other": [:]]] as [[String: Any]?] {
            var data: [String: Any] = ["app": ["pages": ["example/index", "example/other"]]]
            data["modules"] = modules
            let json = String(decoding: try JSONSerialization.data(withJSONObject: data), as: UTF8.self)
            let config = try #require(DMPBundleAppConfig.fromJsonString(json: json))
            #expect(config.entryPagePath == "example/index")
            #expect(config.isContainsPage(pagePath: config.entryPagePath))
            #expect(config.isContainsPage(pagePath: "example/other"))
            #expect(config.getModuleConfig(pagePath: "example/index")?.root == "main")
            #expect(!config.isContainsPage(pagePath: "example/missing"))
        }
    }

    @Test func explicitEntryStillRequiresADeclaredPage() {
        let config = DMPBundleAppConfig(data: [
            "app": ["pages": ["example/index"], "entryPagePath": "/example/index"],
            "modules": [:],
        ])
        #expect(config.isContainsPage(pagePath: config.entryPagePath))
        config.entryPagePath = "example/missing"
        #expect(!config.isContainsPage(pagePath: config.entryPagePath))
        #expect(!DMPBundleAppConfig(data: ["modules": [:]]).isContainsPage(pagePath: "example/index"))
    }

    @Test func subpackagePagesResolveTheirPackageWithoutModuleMetadata() throws {
        let config = try #require(DMPBundleAppConfig.fromJsonString(json: """
        {"app":{"pages":["example/index"],"subPackages":[
            {"root":"features","pages":["detail/index"]}
        ]},"modules":{"features/detail/index":{"navigationBarTitleText":"Detail"}}}
        """))
        #expect(config.isContainsPage(pagePath: "features/detail/index"))
        #expect(config.getRootPackage(pagePath: "features/detail/index") == "features")
        #expect(!config.isContainsPage(pagePath: "detail/index"))
        #expect(!config.isContainsPage(pagePath: "features/missing"))
    }

    @Test func moduleOverridesAndLegacyModuleOnlyPackagesRemainSupported() {
        let config = DMPBundleAppConfig(data: [
            "app": ["pages": ["example/index"], "window": ["navigationBarTitleText": "App"]],
            "modules": [
                "example/index": ["root": "custom", "navigationBarTitleText": "Page"],
                "legacy/index": ["root": "legacy"],
            ],
        ])
        #expect(config.getRootPackage(pagePath: "example/index") == "custom")
        #expect(config.getPageConfig(pagePath: "example/index")["navigationBarTitleText"] as? String == "Page")
        #expect(config.isContainsPage(pagePath: "legacy/index"))
        #expect(config.getRootPackage(pagePath: "legacy/index") == "legacy")
    }
}
