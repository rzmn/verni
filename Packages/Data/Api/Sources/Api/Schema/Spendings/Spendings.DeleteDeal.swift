import DataTransferObjects

extension Spendings {
    public struct DeleteDeal: ApiMethod, SpendingsScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable, Sendable {
            public let dealId: ExpenseDto.Identifier
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/deleteDeal"
        }

        public var method: HttpMethod {
            .post
        }

        public init(dealId: ExpenseDto.Identifier) {
            self.parameters = Parameters(dealId: dealId)
        }
    }
}
