import Foundation

public final class PolicyManagerClient {

    // MARK: - Properties
    private let baseURL: URL
    private let path: String
    private let apiKey: String
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let defaultTimeout: TimeInterval

    // MARK: - Init
    public init(
        baseUrl: URL,
        apiKey: String,
        path: String = "/check/policy",
        requestTimeoutMs: Int = 5_000,
        session: URLSession? = nil
    ) {
        self.baseURL = baseUrl
        self.apiKey  = apiKey
        self.path    = path
        self.defaultTimeout = TimeInterval(Double(requestTimeoutMs) / 1_000)

        // — URLSession —
        if let session = session {
            self.session = session
        } else {
            let cfg = URLSessionConfiguration.default
            cfg.timeoutIntervalForRequest = self.defaultTimeout
            self.session = URLSession(configuration: cfg)
        }

        // — JSON —
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.keyEncodingStrategy = .useDefaultKeys

        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .useDefaultKeys
    }

    // MARK: - Public API (completion handler only)

    @discardableResult
    public func checkPolicy(
        request: PolicyRequest,
        timeoutMs: Int? = nil,
        queue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<PolicyResponse, APIError>) -> Void
    ) -> URLSessionTask? {
        do {
            let urlRequest = try makeURLRequest(body: request, overrideTimeout: timeoutMs)

            let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
                let result = self?.handleResponse(data: data, response: response, error: error)
                             ?? .failure(.invalidResponse)
                queue.async {
                    completion(result)
                }
            }
            task.resume()
            return task
        } catch {
            queue.async {
                completion(.failure(.networkError))
            }
            return nil
        }
    }

    // MARK: - Private helpers

    private func makeURLRequest<T: Encodable>(
        body: T,
        overrideTimeout: Int? = nil
    ) throws -> URLRequest {
        let endpoint = baseURL.appendingPathComponent(path)
        var req      = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.timeoutInterval = TimeInterval(Double(overrideTimeout ?? Int(defaultTimeout * 1000)) / 1_000)
        req.httpBody = try jsonEncoder.encode(body)
        return req
    }

    private func handleResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<PolicyResponse, APIError> {
        if let _ = error {
            return .failure(.networkError)
        }

        guard let http = response as? HTTPURLResponse,
              let data = data else {
            return .failure(.invalidResponse)
        }

        switch http.statusCode {
        case 200..<300:
            do {
                let decoded = try jsonDecoder.decode(PolicyResponse.self, from: data)
                return .success(decoded)
            } catch {
                return .failure(.unknown(error))
            }
        case 401:
            return .failure(.unauthorized)
        default:
            return .failure(.invalidResponse)
        }
    }
}
