import DataTransferObjects

public protocol Persistency: Sendable {
    func userId() async -> UserDto.Identifier

    func getRefreshToken() async -> String
    func update(refreshToken: String) async

    func getProfile() async -> ProfileDto?
    func update(profile: ProfileDto) async
    func user(id: UserDto.Identifier) async -> UserDto?
    func update(users: [UserDto]) async

    func getSpendingCounterparties() async -> [BalanceDto]?
    func updateSpendingCounterparties(_ counterparties: [BalanceDto]) async
    func getSpendingsHistory(counterparty: UserDto.Identifier) async -> [IdentifiableExpenseDto]?
    func updateSpendingsHistory(counterparty: UserDto.Identifier, history: [IdentifiableExpenseDto]) async

    func getFriends(set: Set<FriendshipKindDto>) async -> [FriendshipKindDto: [UserDto]]?
    func update(friends: [FriendshipKindDto: [UserDto]], for set: Set<FriendshipKindDto>) async

    func close() async
    func invalidate() async
}
