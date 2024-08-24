import DataTransferObjects

extension Spendings {
    public struct DeleteDeal: ApiMethod, SpendingsScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable {
            let dealId: DealDto.ID
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/deleteDeal"
        }

        public var method: HttpMethod {
            .post
        }

        public init(dealId: DealDto.ID) {
            self.parameters = Parameters(dealId: dealId)
        }
    }
}
