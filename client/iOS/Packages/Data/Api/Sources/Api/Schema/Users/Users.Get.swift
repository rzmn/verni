import DataTransferObjects

extension Users {
    public struct Get: ApiMethod, UsersScope {
        public typealias Response = [UserDto]

        public struct Parameters: Encodable {
            let ids: [UserDto.ID]

            public init(ids: [UserDto.ID]) {
                self.ids = ids
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
