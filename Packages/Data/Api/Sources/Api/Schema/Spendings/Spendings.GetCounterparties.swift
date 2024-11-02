import DataTransferObjects

extension Spendings {
    public struct GetCounterparties: ApiMethod, SpendingsScope {
        public typealias Response = [BalanceDto]
        public typealias Parameters = NoParameters

        public var path: String {
            scope + "/getCounterparties"
        }

        public var method: HttpMethod {
            .get
        }

        public init() {}
    }
}
