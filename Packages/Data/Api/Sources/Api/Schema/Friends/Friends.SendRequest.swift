import DataTransferObjects

extension Friends {
    public struct SendRequest: ApiMethod, FriendsScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable, Sendable {
            public let target: UserDto.Identifier
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/sendRequest"
        }

        public var method: HttpMethod {
            .post
        }

        public init(target: UserDto.Identifier) {
            self.parameters = Parameters(target: target)
        }
    }
}
