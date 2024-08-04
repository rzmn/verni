import DataTransferObjects

extension Friends {
    public struct AcceptRequest: ApiMethod, FriendsScope {
        public typealias Response = Void

        public struct Parameters: Encodable {
            let sender: UserDto.ID
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/acceptRequest"
        }

        public var method: HttpMethod {
            .get
        }

        public init(sender: UserDto.ID) {
            self.parameters = Parameters(sender: sender)
        }
    }
}
