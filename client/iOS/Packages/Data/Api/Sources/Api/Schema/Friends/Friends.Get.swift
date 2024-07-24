import DataTransferObjects

extension Friends {
    public struct Get: ApiMethod, FriendsScope {
        public typealias Response = [FriendshipKindDto: [UserDto.ID]]

        public struct Parameters: Encodable {
            let statuses: [Int]

            public init(statuses: [Int]) {
                self.statuses = statuses
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/get"
        }

        public var method: HttpMethod {
            .get
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
