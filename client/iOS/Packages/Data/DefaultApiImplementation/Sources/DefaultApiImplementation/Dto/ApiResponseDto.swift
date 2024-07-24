import Api

enum ApiResponseDto<Response: Decodable> {
    case success(Response)
    case failure(ApiErrorDto)
}

extension ApiResponseDto: Decodable {
    enum Status: String, Decodable {
        case ok
        case failed
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case response
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(Status.self, forKey: .status)
        switch status {
        case .ok:
            self = .success(try container.decode(Response.self, forKey: .response))
        case .failed:
            self = .failure(try container.decode(ApiErrorDto.self, forKey: .response))
        }
    }
}
