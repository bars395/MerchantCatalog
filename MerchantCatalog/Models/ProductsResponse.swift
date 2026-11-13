import Foundation

struct ProductsResponse: Decodable {

    // MARK: - Public Properties

    let products: [ProductDTO]
}

struct ProductDTO: Decodable {

    // MARK: - Private Types

    private enum CodingKeys: String, CodingKey {
        case id, title, price, stock, sku, description, thumbnail
    }

    // MARK: - Public Properties

    let id: Int
    let title: String
    let price: Double
    let stock: Int
    let sku: String
    let description: String
    let thumbnail: URL?

    // MARK: - Object Lifecycle

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        price = try container.decode(Double.self, forKey: .price)
        stock = try container.decode(Int.self, forKey: .stock)
        sku = try container.decode(String.self, forKey: .sku)
        description = try container.decode(String.self, forKey: .description)
        // A malformed optional image URL must not invalidate the product record.
        thumbnail = try? container.decode(URL.self, forKey: .thumbnail)
    }
}
