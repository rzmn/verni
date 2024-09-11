import DataTransferObjects

extension Friends {
    public struct Get: ApiMethod, FriendsScope {
        public typealias Response = [Int: [UserDto.ID]]

        public struct Parameters: Encodable, Sendable {
            public let statuses: [Int]
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/get"
        }

        public var method: HttpMethod {
            .get
        }

        public init(statuses: [FriendshipKindDto]) {
            self.parameters = Parameters(statuses: statuses.map(\.rawValue))
        }
    }
}
