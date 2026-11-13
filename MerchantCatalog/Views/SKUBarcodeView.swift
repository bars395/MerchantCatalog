import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct SKUBarcodeView: View {

    // MARK: - Public Properties

    let sku: String

    // MARK: - Public Computed Properties

    var body: some View {
        if let image = Self.barcode(for: sku) {
            Image(decorative: image, scale: 1)
                .resizable()
                .interpolation(.none)
                .frame(height: 72)
                .padding(8)
                .background(Color.white)
                .accessibilityHidden(true)
        } else {
            Text("Barcode unavailable for this SKU")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Private Properties

    private static let context = CIContext()
}

// MARK: - Private Methods

extension SKUBarcodeView {
    private static func barcode(for sku: String) -> CGImage? {
        guard !sku.isEmpty, sku.utf8.allSatisfy({ (0x20...0x7e).contains($0) }) else {
            return nil
        }

        let generator = CIFilter.code128BarcodeGenerator()
        generator.message = Data(sku.utf8)
        generator.quietSpace = 12
        generator.barcodeHeight = 72
        guard let output = generator.outputImage else { return nil }

        return context.createCGImage(output, from: output.extent)
    }
}
