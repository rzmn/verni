import DataTransferObjects

extension Auth {
    public struct ConfirmEmail: ApiMethod, AuthScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable, Sendable {
            let code: String
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/confirmEmail"
        }

        public var method: HttpMethod {
            .put
        }

        public init(code: String) {
            self.parameters = Parameters(code: code)
        }
    }
}
