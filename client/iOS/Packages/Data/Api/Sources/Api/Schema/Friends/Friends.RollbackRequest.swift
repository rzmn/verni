import DataTransferObjects

extension Friends {
    public struct RollbackRequest: ApiMethod, FriendsScope {
        public typealias Response = Void

        public struct Parameters: Encodable {
            let target: String

            public init(target: String) {
                self.target = target
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/rollbackRequest"
        }

        public var method: HttpMethod {
            .post
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
