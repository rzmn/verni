import DataTransferObjects

extension Profile {
    public struct SetDisplayName: ApiMethod, FriendsScope {
        public typealias Response = Void
        public var parameters: Parameters

        public struct Parameters: Encodable {
            let displayName: String

            public init(displayName: String) {
                self.displayName = displayName
            }
        }

        public var path: String {
            scope + "/setDisplayName"
        }

        public var method: HttpMethod {
            .put
        }
    }
}
