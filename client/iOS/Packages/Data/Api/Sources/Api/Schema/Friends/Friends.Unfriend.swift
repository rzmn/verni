import DataTransferObjects

extension Friends {
    public struct Unfriend: ApiMethod, FriendsScope {
        public typealias Response = Void

        public struct Parameters: Encodable {
            let target: UserDto.ID
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/unfriend"
        }

        public var method: HttpMethod {
            .post
        }

        public init(target: UserDto.ID) {
            self.parameters = Parameters(target: target)
        }
    }
}
