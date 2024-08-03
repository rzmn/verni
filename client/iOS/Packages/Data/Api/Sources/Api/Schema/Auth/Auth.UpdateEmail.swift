import DataTransferObjects

extension Auth {
    public struct UpdateEmail: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable {
            let email: String

            public init(email: String) {
                self.email = email
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/updateEmail"
        }

        public var method: HttpMethod {
            .put
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
