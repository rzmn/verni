import Api

struct ApiErrorDto: Error, Decodable {
    let code: ApiErrorCode
    let description: String?
}
