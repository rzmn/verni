import DataTransferObjects

extension Spendings {
    public struct GetBalance: ApiMethod, SpendingsScope {
        public typealias Response = [BalanceDto]
        public typealias Parameters = NoParameters

        public var path: String {
            scope + "/getBalance"
        }

        public var method: HttpMethod {
            .get
        }

        public init() {}
    }
}
