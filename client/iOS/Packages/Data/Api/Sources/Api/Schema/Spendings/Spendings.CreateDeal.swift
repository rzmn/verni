import DataTransferObjects

extension Spendings {
    public struct CreateDeal: ApiMethod, SpendingsScope {
        public typealias Response = [SpendingsPreviewDto]

        public struct Parameters: Encodable {
            let deal: DealDto

            public init(deal: DealDto) {
                self.deal = deal
            }
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/createDeal"
        }

        public var method: HttpMethod {
            .post
        }

        public init(parameters: Parameters) {
            self.parameters = parameters
        }
    }
}
