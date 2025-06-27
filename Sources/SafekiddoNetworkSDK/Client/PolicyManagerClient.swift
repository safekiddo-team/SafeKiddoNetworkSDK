import Foundation

public final class PolicyManagerClient: NSObject, URLSessionDelegate, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let baseURL: URL
    private let apiKey: String
    private var session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let defaultTimeout: TimeInterval
    private let enableSSLPinning: Bool
    private let pinnedCertificates: [Data]
    
    // MARK: - Init
    
    public init(
        baseUrl: URL,
        apiKey: String,
        requestTimeoutMs: Int = 5_000,
        pinnedCertificateNames: [String] = [],
        enableSSLPinning: Bool = true
    ) {
        self.baseURL = baseUrl
        self.apiKey  = apiKey
        self.defaultTimeout = TimeInterval(Double(requestTimeoutMs) / 1_000)
        self.enableSSLPinning = enableSSLPinning
        
        // JSON
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.keyEncodingStrategy = .useDefaultKeys
        
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .useDefaultKeys
        
        // Load pinned certs
        self.pinnedCertificates = pinnedCertificateNames.compactMap { name in
            guard let path = Bundle.main.path(forResource: name, ofType: "cer") else { return nil }
            return try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        
        // Session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = self.defaultTimeout
        
        self.session = URLSession(configuration: config)
        
        super.init()
        
        if enableSSLPinning {
            self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }
    }
    
    // MARK: - Public API
    
    @discardableResult
    public func checkPolicy(
        request: SafekiddoRequest,
        endpointType: SafekiddoEndpointType,
        timeoutMs: Int? = nil,
        queue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<SafekiddoResponse, APIError>) -> Void
    ) -> URLSessionTask? {
        do {
            let urlRequest = try makeURLRequest(
                body: request,
                endpointType: endpointType,
                overrideTimeout: timeoutMs
            )
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
        endpointType: SafekiddoEndpointType,
        overrideTimeout: Int? = nil
    ) throws -> URLRequest {
        let endpoint = baseURL.appendingPathComponent(endpointType.pathComponent)
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.timeoutInterval = TimeInterval(Double(overrideTimeout ?? Int(defaultTimeout * 1000)) / 1_000)
        
        let bodyData = try jsonEncoder.encode(body)
        if let jsonString = String(data: bodyData, encoding: .utf8) {
            print("[PolicyManagerClient] JSON wysyłany:\n\(jsonString)")
        }
        req.httpBody = bodyData
        
        return req
    }
    
    private func handleResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<SafekiddoResponse, APIError> {
        if let error = error {
            print("[PolicyManagerClient] Network error: \(error)")
            return .failure(.networkError)
        }
        guard let http = response as? HTTPURLResponse else {
            print("[PolicyManagerClient] Brak HTTPURLResponse: \(String(describing: response))")
            return .failure(.invalidResponse)
        }
        guard let data = data else {
            print("[PolicyManagerClient] Brak danych, status code: \(http.statusCode)")
            return .failure(.invalidResponse)
        }
        
        print("[PolicyManagerClient] Status code: \(http.statusCode)")
        if let body = String(data: data, encoding: .utf8) {
            print("[PolicyManagerClient] Body:\n\(body)")
        }
        
        switch http.statusCode {
        case 200..<300:
            do {
                let decoded = try jsonDecoder.decode(SafekiddoResponse.self, from: data)
                return .success(decoded)
            } catch {
                print("[PolicyManagerClient] Decoding error: \(error)")
                return .failure(.unknown(error))
            }
        case 401:
            return .failure(.unauthorized)
        default:
            return .failure(.invalidResponse)
        }
    }
    
    // MARK: - URLSessionDelegate (SSL pinning)
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard enableSSLPinning,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let serverCertData = SecCertificateCopyData(serverCert) as Data
        
        if pinnedCertificates.contains(serverCertData) {
            print("[PolicyManagerClient] SSL pinning success")
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            print("[PolicyManagerClient] SSL pinning failed")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
