import Foundation

public struct SpendingDto: Codable, Sendable, Equatable {
    public let userId: UserDto.ID
    public let cost: CostDto

    public init(userId: UserDto.ID, cost: CostDto) {
        self.userId = userId
        self.cost = cost
    }
}
