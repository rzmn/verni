import DataTransferObjects

extension Auth {
    public struct Refresh: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable, Sendable {
            public let refreshToken: String
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/refresh"
        }

        public var method: HttpMethod {
            .put
        }

        public init(refreshToken: String) {
            self.parameters = Parameters(refreshToken: refreshToken)
        }
    }
}
