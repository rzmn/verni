import DataTransferObjects

extension Spendings {
    public struct CreateDeal: ApiMethod, SpendingsScope {
        public typealias Response = NoResponse

        public struct Parameters: Encodable {
            let deal: DealDto
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/createDeal"
        }

        public var method: HttpMethod {
            .post
        }

        public init(deal: DealDto) {
            self.parameters = Parameters(deal: deal)
        }
    }
}
