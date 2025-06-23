import Foundation

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case decodingFailed(Error)
    case serverError(Int)
    case missingData

}
