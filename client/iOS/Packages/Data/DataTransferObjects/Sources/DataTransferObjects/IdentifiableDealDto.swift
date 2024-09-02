import Foundation

public struct DealDto: Codable, Sendable {
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
public struct IdentifiableDealDto: Codable, Sendable {
    public let id: DealDto.ID
    public let deal: DealDto

    public init(id: DealDto.ID, deal: DealDto) {
        self.id = id
        self.deal = deal
    }

    enum CodingKeys: CodingKey {
        case id
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.deal = try DealDto(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try deal.encode(to: encoder)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<DealDto, T>) -> T {
        deal[keyPath: keyPath]
    }
}
