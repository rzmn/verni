import DataTransferObjects

extension Users {
    public struct Search: ApiMethod, UsersScope {
        public typealias Response = [UserDto]

        public struct Parameters: Encodable {
            let query: String

            public init(query: String) {
                self.query = query
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/search"
        }

        public var method: HttpMethod {
            .get
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
