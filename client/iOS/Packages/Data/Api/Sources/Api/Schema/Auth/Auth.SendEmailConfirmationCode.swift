import DataTransferObjects

extension Auth {
    public struct SendEmailConfirmationCode: ApiMethod, AuthScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable, Sendable {}
        public let parameters: Parameters

        public var path: String {
            scope + "/sendEmailConfirmationCode"
        }

        public var method: HttpMethod {
            .put
        }

        public init() {
            self.parameters = Parameters()
        }
    }
}
