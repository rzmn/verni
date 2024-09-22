import Foundation

public struct SpendingDto: Codable, Sendable, Equatable {
    public let userId: UserDto.Identifier
    public let cost: CostDto

    public init(userId: UserDto.Identifier, cost: CostDto) {
        self.userId = userId
        self.cost = cost
    }
}
