import Convenience
import Foundation

actor DefaultUrlConfiguration {
    private let endpoint: URL
    private var authHeaderValue: String?
    
    init(endpoint: URL) {
        self.endpoint = endpoint
    }
    
    func updateAuthHeaderValue(_ authHeaderValue: String?) {
        self.authHeaderValue = authHeaderValue
    }
}

extension DefaultUrlConfiguration: UrlConfiguration {
    nonisolated func sessionConfiguration() -> URLSessionConfiguration {
        modify(URLSessionConfiguration.default) {
            $0.timeoutIntervalForRequest = 600
            $0.timeoutIntervalForResource = 3600
            $0.httpMaximumConnectionsPerHost = 1
            $0.requestCachePolicy = .reloadIgnoringLocalCacheData
            $0.networkServiceType = .responsiveData
            $0.shouldUseExtendedBackgroundIdleMode = true
            $0.connectionProxyDictionary = [:]
        }
    }
    
    func urlRequest() -> URLRequest {
        modify(URLRequest(url: endpoint)) {
            if let authHeaderValue {
                $0.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
            }
            $0.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            $0.setValue("text/event-stream", forHTTPHeaderField: "Content-Type")
            $0.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            $0.setValue("keep-alive", forHTTPHeaderField: "Connection")
            $0.httpMethod = "GET"
            $0.timeoutInterval = 600
        }
    }
}
