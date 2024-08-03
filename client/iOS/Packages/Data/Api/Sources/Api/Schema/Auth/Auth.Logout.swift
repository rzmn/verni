import DataTransferObjects

extension Auth {
    public struct Logout: ApiMethod, AuthScope {
        public typealias Response = Void

        public var path: String {
            scope + "/logout"
        }

        public var method: HttpMethod {
            .delete
        }

        public init() {}
    }
}
