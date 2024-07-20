import Foundation

public struct DealDto: Codable {
    public let timestamp: Int64
    public let details: String
    public let cost: CostDto
    public let currency: String
    public let spendings: [SpendingDto]

    public init(
        timestamp: Int64,
        details: String,
        cost: CostDto,
        currency: String,
        spendings: [SpendingDto]
    ) {
        self.timestamp = timestamp
        self.details = details
        self.cost = cost
        self.currency = currency
        self.spendings = spendings
    }
}

public extension DealDto {
    typealias ID = String
}

@dynamicMemberLookup
public struct IdentifiableDealDto: Decodable {
    public let id: DealDto.ID
    private let deal: DealDto

    enum CodingKeys: CodingKey {
        case id
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.deal = try DealDto(from: decoder)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<DealDto, T>) -> T {
        deal[keyPath: keyPath]
    }
}
