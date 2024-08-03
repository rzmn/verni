import DataTransferObjects

extension Profile {
    public struct SetAvatar: ApiMethod, FriendsScope {
        public typealias Response = Void
        public var parameters: Parameters

        public struct Parameters: Encodable {
            let dataBase64: String

            public init(dataBase64: String) {
                self.dataBase64 = dataBase64
            }
        }

        public var path: String {
            scope + "/setAvatar"
        }

        public var method: HttpMethod {
            .put
        }
    }
}
