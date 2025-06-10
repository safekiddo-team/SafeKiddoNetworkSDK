import Foundation

public enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case decodingFailed(Error)
    case serverError(Int)
    case missingData
}
