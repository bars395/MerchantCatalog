struct DependencyContainer {

    // MARK: - Public Properties

    let productsService: ProductsServiceProtocol
    let imageService: ImageServiceProtocol

    // MARK: - Object Lifecycle

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        productsService = ProductsService(networkService: networkService)
        imageService = ImageService(networkService: networkService)
    }
}
