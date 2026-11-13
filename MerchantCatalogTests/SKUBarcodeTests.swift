import SwiftUI
import Vision
import XCTest
@testable import MerchantCatalog

@MainActor
final class SKUBarcodeTests: XCTestCase {

    // MARK: - Public Methods

    func testDetailBarcodeScansAsOriginalSKUInDarkMode() throws {
        let sku = "00-FyUL-101"
        let view = SKUBarcodeView(sku: sku)
            .frame(width: 320)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let image = try XCTUnwrap(renderer.cgImage)

        let request = VNDetectBarcodesRequest()
        request.revision = VNDetectBarcodesRequestRevision1
        request.symbologies = [.code128]
        try VNImageRequestHandler(cgImage: image).perform([request])

        XCTAssertEqual(request.results?.first?.payloadStringValue, sku)
    }
}
