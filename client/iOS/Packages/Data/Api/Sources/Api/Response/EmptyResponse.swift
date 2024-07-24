import Foundation

struct EmptyResponse: Decodable, Response {
    static var overridenValue: EmptyResponse? {
        EmptyResponse()
    }
}
