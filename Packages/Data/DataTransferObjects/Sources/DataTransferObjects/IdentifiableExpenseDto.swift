import Foundation

public extension ExpenseDto {
    typealias Identifier = String
}

@dynamicMemberLookup
public struct IdentifiableExpenseDto: Codable, Sendable, Equatable {
    public let id: ExpenseDto.Identifier
    public let deal: ExpenseDto

    public init(id: ExpenseDto.Identifier, deal: ExpenseDto) {
        self.id = id
        self.deal = deal
    }

    enum CodingKeys: CodingKey {
        case id
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.deal = try ExpenseDto(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try deal.encode(to: encoder)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<ExpenseDto, T>) -> T {
        deal[keyPath: keyPath]
    }
}
