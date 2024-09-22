import Foundation

public typealias CurrencyDto = String

public struct SpendingsPreviewDto: Codable, Sendable, Equatable {
    public let counterparty: UserDto.Identifier
    public let balance: [CurrencyDto: Int64]

    public init(counterparty: UserDto.Identifier, balance: [CurrencyDto: Int64]) {
        self.counterparty = counterparty
        self.balance = balance
    }
}
