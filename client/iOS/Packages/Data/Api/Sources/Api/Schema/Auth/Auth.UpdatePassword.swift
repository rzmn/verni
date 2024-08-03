import DataTransferObjects

extension Auth {
    public struct UpdatePassword: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable {
            let old: String
            let new: String

            public init(old: String, new: String) {
                self.old = old
                self.new = new
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/updatePassword"
        }

        public var method: HttpMethod {
            .put
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
