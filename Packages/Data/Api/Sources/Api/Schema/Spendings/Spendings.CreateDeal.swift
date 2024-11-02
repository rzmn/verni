import DataTransferObjects

extension Spendings {
    public struct CreateDeal: ApiMethod, SpendingsScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable, Sendable {
            public let deal: ExpenseDto
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/createDeal"
        }

        public var method: HttpMethod {
            .post
        }

        public init(deal: ExpenseDto) {
            self.parameters = Parameters(deal: deal)
        }
    }
}
