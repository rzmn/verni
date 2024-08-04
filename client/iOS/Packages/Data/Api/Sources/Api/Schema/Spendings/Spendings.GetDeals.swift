import DataTransferObjects

extension Spendings {
    public struct GetDeals: ApiMethod, SpendingsScope {
        public typealias Response = [IdentifiableDealDto]

        public struct Parameters: Encodable {
            let counterparty: UserDto.ID
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/getDeals"
        }

        public var method: HttpMethod {
            .get
        }

        public init(counterparty: UserDto.ID) {
            self.parameters = Parameters(counterparty: counterparty)
        }
    }
}
