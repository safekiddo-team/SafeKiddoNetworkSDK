import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case invalidResponse
    case networkError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Unauthorized: Invalid API key"
        case .invalidResponse: return "The server returned an invalid response"
        case .networkError: return "Network error while making API request"
        case .unknown(let error): return "Unknown error: \(error.localizedDescription)"
        }
    }
}
