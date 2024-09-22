import DataTransferObjects

extension Spendings {
    public struct GetDeals: ApiMethod, SpendingsScope {
        public typealias Response = [IdentifiableDealDto]

        public struct Parameters: Encodable, Sendable {
            public let counterparty: UserDto.Identifier
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/getDeals"
        }

        public var method: HttpMethod {
            .get
        }

        public init(counterparty: UserDto.Identifier) {
            self.parameters = Parameters(counterparty: counterparty)
        }
    }
}
