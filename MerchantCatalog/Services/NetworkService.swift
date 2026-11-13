import Foundation

// MARK: - Types

enum NetworkServiceError: Error, Equatable {
    case invalidResponse
    case httpStatus(Int)
}

protocol NetworkServiceProtocol: Sendable {
    func data(from url: URL) async throws -> Data
}

struct NetworkService {

    // MARK: - Private Properties

    private let session: URLSession

    // MARK: - Object Lifecycle

    init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
    }
}

// MARK: - NetworkServiceProtocol

extension NetworkService: NetworkServiceProtocol {
    func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkServiceError.httpStatus(httpResponse.statusCode)
        }
        return data
    }
}
