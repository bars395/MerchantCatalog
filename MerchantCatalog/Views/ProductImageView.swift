import SwiftUI
import UIKit

struct ProductImageView: View {

    // MARK: - Public Properties

    let imageState: ProductImageState
    let height: CGFloat
    let contentMode: ContentMode

    // MARK: - Public Computed Properties

    var body: some View {
        Group {
            switch imageState {
            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .accessibilityLabel("Product image")

            case .failed:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(Color.secondary)
                    .accessibilityLabel("Product image unavailable")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading product image")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
