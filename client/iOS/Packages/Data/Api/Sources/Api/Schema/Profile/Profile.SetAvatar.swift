import DataTransferObjects

extension Profile {
    public struct SetAvatar: ApiMethod, ProfileScope {
        public typealias Response = NoResponse
        public var parameters: Parameters

        public struct Parameters: Encodable {
            let dataBase64: String
        }

        public var path: String {
            scope + "/setAvatar"
        }

        public var method: HttpMethod {
            .put
        }

        public init(dataBase64: String) {
            self.parameters = Parameters(dataBase64: dataBase64)
        }
    }
}
