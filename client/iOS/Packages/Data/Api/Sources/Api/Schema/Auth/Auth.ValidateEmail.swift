import DataTransferObjects

extension Auth {
    public struct ValidateEmail: ApiMethod, AuthScope {
        public typealias Response = Bool

        public struct Parameters: Encodable {
            let email: String

            public init(email: String) {
                self.email = email
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/validateEmail"
        }

        public var method: HttpMethod {
            .get
        }

        public init(email: String) {
            self.parameters = Parameters(email: email)
        }
    }
}
