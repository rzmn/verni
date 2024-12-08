import DataTransferObjects

public protocol Persistency: Sendable {
    subscript<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        descriptor: Schema<Key, Value>.Index
    ) -> Value? { get async }
    
    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        value: Value,
        for descriptor: Schema<Key, Value>.Index
    ) async
    
    var userId: UserDto.Identifier { get async }
    var refreshToken: String { get async }
    func close() async
    func invalidate() async
}

extension Schema where Key == [FriendshipKindDto] {
    public func index(for set: Set<FriendshipKindDto>) -> Schema.Index {
        index(
            for: set.sorted { lhs, rhs in
                lhs.rawValue < rhs.rawValue
            }
        )
    }
}

public enum Schemas {
    public static var refreshToken: Schema<Unkeyed, String> {
        Schema(id: "refreshToken")
    }
    
    public static var profile: Schema<Unkeyed, ProfileDto> {
        Schema(id: "profile")
    }
    
    public static var users: Schema<UserDto.Identifier, UserDto> {
        Schema(id: "users")
    }
    
    public static var spendingCounterparties: Schema<Unkeyed, [BalanceDto]> {
        Schema(id: "spendingCounterparties")
    }
    
    public static var spendingsHistory: Schema<UserDto.Identifier, [IdentifiableExpenseDto]> {
        Schema(id: "spendingsHistory")
    }
    
    public static var friends: Schema<[FriendshipKindDto], [FriendshipKindDto: [UserDto]]> {
        Schema(id: "friends")
    }
}
