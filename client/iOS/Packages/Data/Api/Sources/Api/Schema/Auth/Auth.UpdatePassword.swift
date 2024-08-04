import DataTransferObjects

extension Auth {
    public struct UpdatePassword: ApiMethod, AuthScope {
        public typealias Response = AuthTokenDto

        public struct Parameters: Encodable {
            let old: String
            let new: String
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/updatePassword"
        }

        public var method: HttpMethod {
            .put
        }

        public init(old: String, new: String) {
            self.parameters = Parameters(old: old, new: new)
        }
    }
}
