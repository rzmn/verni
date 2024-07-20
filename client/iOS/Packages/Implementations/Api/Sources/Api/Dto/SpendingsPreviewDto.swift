import Foundation

public typealias CurrencyDto = String

public struct SpendingsPreviewDto: Decodable {
    public let counterparty: UserDto.ID
    public let balance: [CurrencyDto: Int64]
}
