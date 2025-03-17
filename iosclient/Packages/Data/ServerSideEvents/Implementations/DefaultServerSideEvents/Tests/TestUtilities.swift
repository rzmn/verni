import Foundation
import ServerSideEvents
@testable import DefaultServerSideEvents

class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var responseStatusCode: Int = 200
    nonisolated(unsafe) static var error: Error?
    nonisolated(unsafe) static var requestedURLs: [URL] = []
    
    static func reset() {
        responseData = nil
        responseStatusCode = 200
        error = nil
        requestedURLs = []
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let client = client else { return }
        
        if let url = request.url {
            Self.requestedURLs.append(url)
        }
        
        if let error = Self.error {
            client.urlProtocol(self, didFailWithError: error)
            return
        }
        
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: Self.responseStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        if let data = Self.responseData {
            client.urlProtocol(self, didLoad: data)
        }
        
        client.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

actor MockUrlConfiguration: UrlConfiguration {
    private let configuration: URLSessionConfiguration
    private let endpoint: URL
    private var authHeaderValue: String?
    
    init(sessionConfiguration: URLSessionConfiguration, endpoint: URL) {
        self.configuration = sessionConfiguration
        self.endpoint = endpoint
    }
    
    nonisolated func sessionConfiguration() -> URLSessionConfiguration {
        configuration
    }
    
    func urlRequest() async -> URLRequest {
        var request = URLRequest(url: endpoint)
        if let authHeaderValue {
            request.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        }
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("text/event-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.httpMethod = "GET"
        return request
    }
    
    func updateAuthHeaderValue(_ authHeaderValue: String?) {
        self.authHeaderValue = authHeaderValue
    }
} 
