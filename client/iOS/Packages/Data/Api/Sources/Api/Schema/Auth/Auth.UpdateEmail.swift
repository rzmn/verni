import DataTransferObjects

extension Auth {
    public struct UpdateEmail: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable, Sendable {
            let email: String
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/updateEmail"
        }

        public var method: HttpMethod {
            .put
        }

        public init(email: String) {
            self.parameters = Parameters(email: email)
        }
    }
}
