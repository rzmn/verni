import DataTransferObjects

extension Auth {
    public struct SendEmailConfirmationCode: ApiMethod, AuthScope {
        public typealias Response = Void

        public struct Parameters: Encodable {}
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
