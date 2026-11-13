import Observation
import UIKit

// MARK: - Types

enum ProductImageState {
    case idle
    case loading
    case loaded(UIImage)
    case failed
}

@Observable
@MainActor
final class Product: Identifiable {

    // MARK: - Public Properties

    let id: Int
    let title: String
    let price: Double
    let stock: Int
    let sku: String
    let description: String
    let thumbnail: URL?
    // For this 3–4 hour exercise, the list and detail screens share a single
    // product model that also holds the image loading state.
    //
    // In a larger project, I'd separate this into two entities:
    // a domain model containing only product data, and a presentation model
    // managing the UIImage and its loading state for the UI.
    // This would keep the domain layer independent of UIKit.
    var imageState: ProductImageState = .idle

    // MARK: - Object Lifecycle

    init(dto: ProductDTO) {
        id = dto.id
        title = dto.title
        price = dto.price
        stock = dto.stock
        sku = dto.sku
        description = dto.description
        thumbnail = dto.thumbnail
    }
}
