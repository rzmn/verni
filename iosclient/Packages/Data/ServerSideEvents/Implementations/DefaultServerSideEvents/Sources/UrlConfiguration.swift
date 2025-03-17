import Foundation
import Convenience

protocol UrlConfiguration: Sendable {
    func sessionConfiguration() -> URLSessionConfiguration
    func urlRequest() async -> URLRequest
    
    func updateAuthHeaderValue(_ authHeaderValue: String?) async
}

