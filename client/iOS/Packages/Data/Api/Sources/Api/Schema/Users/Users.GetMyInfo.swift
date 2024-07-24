import DataTransferObjects

extension Users {
    public struct GetMyInfo: ApiMethod, UsersScope {
        public typealias Response = UserDto
        public typealias Parameters = Void

        public var path: String {
            scope + "/getMyInfo"
        }

        public var method: HttpMethod {
            .get
        }
        
        public init() {}
    }
}
