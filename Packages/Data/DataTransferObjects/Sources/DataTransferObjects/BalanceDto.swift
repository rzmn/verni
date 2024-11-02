import Foundation

public typealias CurrencyDto = String

public struct BalanceDto: Codable, Sendable, Equatable {
    public let counterparty: UserDto.Identifier
    public let currencies: [CurrencyDto: CostDto]

    public init(counterparty: UserDto.Identifier, currencies: [CurrencyDto: CostDto]) {
        self.counterparty = counterparty
        self.currencies = currencies
    }
}
