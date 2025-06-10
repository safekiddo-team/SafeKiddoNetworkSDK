import Foundation
import Security


public final class APIClient: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let baseURL: URL
    private var session: URLSession
    private let defaultHeaders: [String: String]
    private let pinnedCertificates: [Data]
    private let enableSSLPinning: Bool
    
    public init(baseURL: URL,
                headers: [String: String] = [:],
                pinnedCertificateNames: [String] = [],
                enableSSLPinning: Bool = true) {
        self.baseURL = baseURL
        self.defaultHeaders = headers
        self.enableSSLPinning = enableSSLPinning
        self.pinnedCertificates = pinnedCertificateNames.compactMap { name in
            guard let path = Bundle.main.path(forResource: name, ofType: "cer") else { return nil }
            return try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        let config = URLSessionConfiguration.default
        
        self.session = URLSession(configuration: config)
        super.init()
        
        if enableSSLPinning {
            self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }
    }
    
    public func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // Budowanie URL bez nadpisywania ścieżki baseURL
        let trimmedEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let url = baseURL.appendingPathComponent(trimmedEndpoint)
        
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        let allHeaders = defaultHeaders.merging(headers ?? [:]) { _, new in new }
        for (key, value) in allHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let params = parameters, method != .get {
            request.httpBody = try? JSONSerialization.data(withJSONObject: params)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        print("[APIClient] Request to: \(url.absoluteString), Method: \(method.rawValue)")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[APIClient] Error: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidURL))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data,
                   let errorMessage = String(data: data, encoding: .utf8) {
                    print("[APIClient] Server responded with error message:")
                    print(errorMessage)
                } else {
                    print("[APIClient] Server error but no readable response body.")
                }
                
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.missingData))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                print("[APIClient] Response decoded successfully")
                completion(.success(decoded))
            } catch {
                print("[APIClient] Decoding error: \(error)")
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
    
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
            print("[APIClient] SSL pinning success")
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            print("[APIClient] SSL pinning failed")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
