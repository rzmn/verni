import Api

protocol ApiResponse: Decodable & Sendable {
    associatedtype Success

    var result: Result<Success, ApiErrorDto> { get }
}

enum VoidApiResponseDto: Decodable & Sendable {
    case success
    case failure(ApiErrorDto)

    private enum CodingKeys: String, CodingKey {
        case status
        case response
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(ResponseStatus.self, forKey: .status)
        switch status {
        case .ok:
            self = .success
        case .failed:
            self = .failure(try container.decode(ApiErrorDto.self, forKey: .response))
        }
    }
}

extension VoidApiResponseDto: ApiResponse {
    typealias Success = Void

    var result: Result<Void, ApiErrorDto> {
        switch self {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(apiError)
        }
    }
}

enum ApiResponseDto<Response: Decodable & Sendable>: Sendable {
    case success(Response)
    case failure(ApiErrorDto)

    private enum CodingKeys: String, CodingKey {
        case status
        case response
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(ResponseStatus.self, forKey: .status)
        switch status {
        case .ok:
            self = .success(try container.decode(Response.self, forKey: .response))
        case .failed:
            self = .failure(try container.decode(ApiErrorDto.self, forKey: .response))
        }
    }
}

extension ApiResponseDto: ApiResponse {
    typealias Success = Response

    var result: Result<Response, ApiErrorDto> {
        switch self {
        case .success(let response):
            return .success(response)
        case .failure(let apiError):
            return .failure(apiError)
        }
    }
}
