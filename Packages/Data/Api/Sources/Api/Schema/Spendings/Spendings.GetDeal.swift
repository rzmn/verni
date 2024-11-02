import DataTransferObjects

extension Spendings {
    public struct GetDeal: ApiMethod, SpendingsScope {
        public typealias Response = ExpenseDto

        public struct Parameters: Encodable, Sendable {
            public let dealId: ExpenseDto.Identifier
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/getDeal"
        }

        public var method: HttpMethod {
            .get
        }

        public init(dealId: ExpenseDto.Identifier) {
            self.parameters = Parameters(dealId: dealId)
        }
    }
}
