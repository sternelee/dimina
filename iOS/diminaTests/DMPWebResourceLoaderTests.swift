//
//  DMPWebResourceLoaderTests.swift
//  diminaTests
//

import ImageIO
import UIKit
import UniformTypeIdentifiers
import XCTest
@testable import dimina

@MainActor
final class DMPWebResourceLoaderTests: XCTestCase {

    func testHEIFFamilyUsesStandardMimeTypes() {
        XCTAssertEqual(DMPWebResourceLoader.mimeType(forExtension: "HEIC"), "image/heic")
        XCTAssertEqual(DMPWebResourceLoader.mimeType(forExtension: "heif"), "image/heif")
    }

    func testHEIFFamilyOnlyNeedsFallbackBeforeWebKitSupport() {
        XCTAssertTrue(DMPWebResourceLoader.requiresHEIFTranscode(
            pathExtension: "HEIC",
            webKitSupportsHEIF: false
        ))
        XCTAssertFalse(DMPWebResourceLoader.requiresHEIFTranscode(
            pathExtension: "heif",
            webKitSupportsHEIF: true
        ))
        XCTAssertFalse(DMPWebResourceLoader.requiresHEIFTranscode(
            pathExtension: "jpeg",
            webKitSupportsHEIF: false
        ))
    }

    func testHEIFFallbackReturnsJPEGData() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let sourceImage = renderer.image { context in
            context.cgContext.setFillColor(UIColor.red.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let sourceData = NSMutableData()
        let heicType = try XCTUnwrap(UTType(filenameExtension: "heic"))
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(
            sourceData,
            heicType.identifier as CFString,
            1,
            nil
        ))
        CGImageDestinationAddImage(destination, try XCTUnwrap(sourceImage.cgImage), nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))

        let payload = try DMPWebResourceLoader.makePayload(
            data: sourceData as Data,
            pathExtension: "heic",
            webKitSupportsHEIF: false
        )

        XCTAssertEqual(payload.mimeType, "image/jpeg")
        XCTAssertEqual(Array(payload.data.prefix(2)), [0xFF, 0xD8])
    }

    func testSupportedWebKitReceivesOriginalHEICPayload() throws {
        let sourceData = Data([0x01, 0x02, 0x03])

        let payload = try DMPWebResourceLoader.makePayload(
            data: sourceData,
            pathExtension: "heic",
            webKitSupportsHEIF: true
        )

        XCTAssertEqual(payload.mimeType, "image/heic")
        XCTAssertEqual(payload.data, sourceData)
    }
}
