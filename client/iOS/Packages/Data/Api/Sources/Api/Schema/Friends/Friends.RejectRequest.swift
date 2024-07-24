import DataTransferObjects

extension Friends {
    public struct RejectRequest: ApiMethod, FriendsScope {
        public typealias Response = Void

        public struct Parameters: Encodable {
            let sender: String

            public init(sender: String) {
                self.sender = sender
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/rejectRequest"
        }

        public var method: HttpMethod {
            .post
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
