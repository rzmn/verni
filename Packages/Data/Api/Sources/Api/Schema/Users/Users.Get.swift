import DataTransferObjects

extension Users {
    public struct Get: ApiMethod, UsersScope {
        public typealias Response = [UserDto]

        public struct Parameters: Encodable, Sendable {
            let ids: [UserDto.ID]
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/get"
        }

        public var method: HttpMethod {
            .get
        }

        public init(ids: [UserDto.ID]) {
            self.parameters = Parameters(ids: ids)
        }
    }
}
