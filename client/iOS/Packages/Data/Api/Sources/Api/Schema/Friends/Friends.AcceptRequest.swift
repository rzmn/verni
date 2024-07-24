import DataTransferObjects

extension Friends {
    public struct AcceptRequest: ApiMethod, FriendsScope {
        public typealias Response = Void

        public struct Parameters: Encodable {
            let sender: String

            public init(sender: String) {
                self.sender = sender
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/acceptRequest"
        }

        public var method: HttpMethod {
            .get
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
