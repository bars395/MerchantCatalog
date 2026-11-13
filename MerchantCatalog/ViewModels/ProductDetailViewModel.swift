@MainActor
final class ProductDetailViewModel {

    // MARK: - Public Properties

    let product: Product

    // MARK: - Private Properties

    private let copySKUAction: @MainActor (String) -> Void

    // MARK: - Object Lifecycle

    init(
        product: Product,
        copySKU: @escaping @MainActor (String) -> Void
    ) {
        self.product = product
        self.copySKUAction = copySKU
    }

    // MARK: - Public Methods

    func copySKU() {
        copySKUAction(product.sku)
    }
}
