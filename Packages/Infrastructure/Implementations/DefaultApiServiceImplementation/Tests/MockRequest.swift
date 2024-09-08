import ApiService
import Logging

struct MockResponse: Codable {}

class MockRequest: ApiServiceRequest, Loggable, @unchecked Sendable {
    static var accessTokenShouldFailLabel: String {
        "accessTokenShouldFailLabel"
    }

    let logger: Logger = .shared
    let label: String

    let path: String = ""
    let parameters: [String: String] = [:]
    let httpMethod: String = ""

    init(label: String, headers: [String : String] = [:]) {
        self.label = label
        self.headers = headers
    }

    var headers: [String: String] = [:]
    func setHeader(key: String, value: String) {
        logI { "req[\(label)] \(key)=\(value)" }
        headers[key] = value
    }
}
