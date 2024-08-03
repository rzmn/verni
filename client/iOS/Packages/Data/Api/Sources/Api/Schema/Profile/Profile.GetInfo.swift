import DataTransferObjects

extension Profile {
    public struct GetInfo: ApiMethod, FriendsScope {
        public typealias Response = ProfileDto

        public init() {}

        public var path: String {
            scope + "/getInfo"
        }

        public var method: HttpMethod {
            .get
        }
    }
}
