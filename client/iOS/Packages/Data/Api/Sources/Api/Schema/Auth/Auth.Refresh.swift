import DataTransferObjects

extension Auth {
    public struct Refresh: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable {
            let refreshToken: String

            public init(refreshToken: String) {
                self.refreshToken = refreshToken
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/refresh"
        }

        public var method: HttpMethod {
            .put
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
