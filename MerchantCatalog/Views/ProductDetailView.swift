import SwiftUI

struct ProductDetailView: View {

    // MARK: - Public Properties

    let viewModel: ProductDetailViewModel

    // MARK: - Public Computed Properties

    var body: some View {
        let product = viewModel.product
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProductImageView(imageState: product.imageState, height: 260, contentMode: .fit)

                Text(product.title)
                    .font(.largeTitle.weight(.bold))

                ProductInventorySection(price: product.price, stock: product.stock)
                ProductSKUSection(sku: product.sku, onCopy: viewModel.copySKU)
                ProductDescriptionSection(description: product.description)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Private Types

private struct ProductInventorySection: View {

    // MARK: - Public Properties

    let price: Double
    let stock: Int

    // MARK: - Public Computed Properties

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(price, format: .currency(code: "USD"))
            } icon: {
                Image(systemName: "tag")
            }
            .font(.title3.weight(.semibold))

            Label {
                Text(stock == 0 ? "Out of stock" : "\(stock) in stock")
            } icon: {
                Image(systemName: "shippingbox")
            }
            .foregroundStyle(stock == 0 ? Color.red : Color.primary)
        }
    }
}

private struct ProductSKUSection: View {

    // MARK: - Public Properties

    let sku: String
    let onCopy: () -> Void

    // MARK: - Public Computed Properties

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SKU")
                .font(.headline)
            HStack {
                Text(sku)
                    .textSelection(.enabled)
                    .font(.body.monospaced())
                Spacer()
                Button(action: onCopy) {
                    Label("Copy SKU", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }

            SKUBarcodeView(sku: sku)
        }
    }
}

private struct ProductDescriptionSection: View {

    // MARK: - Public Properties

    let description: String

    // MARK: - Public Computed Properties

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
            Text(description)
                .font(.body)
                .foregroundStyle(Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
