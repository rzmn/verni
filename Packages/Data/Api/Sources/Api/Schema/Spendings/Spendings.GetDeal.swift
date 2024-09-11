import DataTransferObjects

extension Spendings {
    public struct GetDeal: ApiMethod, SpendingsScope {
        public typealias Response = DealDto

        public struct Parameters: Encodable, Sendable {
            public let dealId: DealDto.ID
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/getDeal"
        }

        public var method: HttpMethod {
            .get
        }

        public init(dealId: DealDto.ID) {
            self.parameters = Parameters(dealId: dealId)
        }
    }
}
