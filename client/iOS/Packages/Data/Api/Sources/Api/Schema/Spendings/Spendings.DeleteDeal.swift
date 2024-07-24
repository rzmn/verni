import DataTransferObjects

extension Spendings {
    public struct DeleteDeal: ApiMethod, SpendingsScope {
        public typealias Response = [SpendingsPreviewDto]

        public struct Parameters: Encodable {
            let dealId: DealDto.ID

            public init(dealId: DealDto.ID) {
                self.dealId = dealId
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/deleteDeal"
        }

        public var method: HttpMethod {
            .post
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
