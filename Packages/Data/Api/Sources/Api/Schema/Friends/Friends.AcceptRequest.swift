import DataTransferObjects

extension Friends {
    public struct AcceptRequest: ApiMethod, FriendsScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable, Sendable {
            let sender: UserDto.ID
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/acceptRequest"
        }

        public var method: HttpMethod {
            .post
        }

        public init(sender: UserDto.ID) {
            self.parameters = Parameters(sender: sender)
        }
    }
}
