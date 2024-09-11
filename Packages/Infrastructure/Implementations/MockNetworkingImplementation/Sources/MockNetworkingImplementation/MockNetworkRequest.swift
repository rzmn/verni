import Networking

struct MockNetworkRequest: NetworkRequest {
    let path: String
    let headers: [String: String]
    let parameters: [String: String]
    let httpMethod: String
}
