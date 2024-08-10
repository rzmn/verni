import DataTransferObjects

extension Auth {
    public struct RegisterForPushNotifications: ApiMethod, AuthScope {
        public typealias Response = Void

        public struct Parameters: Encodable {
            let token: String
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/registerForPushNotifications"
        }

        public var method: HttpMethod {
            .put
        }

        public init(token: String) {
            self.parameters = Parameters(token: token)
        }
    }
}
