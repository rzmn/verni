import DataTransferObjects

extension Spendings {
    public struct GetCounterparties: ApiMethod, SpendingsScope {
        public typealias Response = [SpendingsPreviewDto]
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
