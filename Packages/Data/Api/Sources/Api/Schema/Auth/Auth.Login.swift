import DataTransferObjects

extension Auth {
    public struct Login: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable, Sendable {
            public let credentials: CredentialsDto
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/login"
        }

        public var method: HttpMethod {
            .put
        }

        public init(credentials: CredentialsDto) {
            self.parameters = Parameters(credentials: credentials)
        }
    }
}
