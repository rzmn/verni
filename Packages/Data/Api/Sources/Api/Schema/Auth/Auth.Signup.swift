import DataTransferObjects

extension Auth {
    public struct Signup: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable, Sendable {
            let credentials: CredentialsDto
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/signup"
        }

        public var method: HttpMethod {
            .put
        }

        public init(credentials: CredentialsDto) {
            self.parameters = Parameters(credentials: credentials)
        }
    }
}
