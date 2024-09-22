import DataTransferObjects

extension Friends {
    public struct RejectRequest: ApiMethod, FriendsScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable, Sendable {
            public let sender: UserDto.Identifier
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/rejectRequest"
        }

        public var method: HttpMethod {
            .post
        }

        public init(sender: UserDto.Identifier) {
            self.parameters = Parameters(sender: sender)
        }
    }
}
