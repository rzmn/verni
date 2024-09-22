import DataTransferObjects

extension Users {
    public struct Get: ApiMethod, UsersScope {
        public typealias Response = [UserDto]

        public struct Parameters: Encodable, Sendable {
            public let ids: [UserDto.Identifier]
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/get"
        }

        public var method: HttpMethod {
            .get
        }

        public init(ids: [UserDto.Identifier]) {
            self.parameters = Parameters(ids: ids)
        }
    }
}
