import Api

struct ApiErrorDto: Error, Decodable, Sendable {
    let code: ApiErrorCode
    let description: String?
}
