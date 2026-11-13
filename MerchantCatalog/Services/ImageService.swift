import UIKit

// MARK: - Types

enum ImageServiceError: Error {
    case invalidURL
    case invalidImageData
}

protocol ImageServiceProtocol: Sendable {
    func image(from url: URL) async throws -> UIImage
}

actor ImageService {

    // MARK: - Private Properties

    private let cache = NSCache<NSURL, UIImage>()
    private let networkService: NetworkServiceProtocol

    // MARK: - Object Lifecycle

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
}

// MARK: - ImageServiceProtocol

extension ImageService: ImageServiceProtocol {
    func image(from url: URL) async throws -> UIImage {
        guard let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            throw ImageServiceError.invalidURL
        }

        let cacheKey = url as NSURL
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let data = try await networkService.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageServiceError.invalidImageData
        }

        cache.setObject(image, forKey: cacheKey)
        return image
    }
}
