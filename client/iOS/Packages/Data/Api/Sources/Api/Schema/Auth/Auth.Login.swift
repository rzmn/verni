import DataTransferObjects

extension Auth {
    public struct Login: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable {
            let credentials: CredentialsDto

            public init(credentials: CredentialsDto) {
                self.credentials = credentials
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/login"
        }

        public var method: HttpMethod {
            .put
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
