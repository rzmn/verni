import DataTransferObjects

public protocol Persistency: Sendable {
    func userId() async -> UserDto.Identifier

    func getRefreshToken() async -> String
    func update(refreshToken: String) async

    func getProfile() async -> ProfileDto?
    func update(profile: ProfileDto) async
    func user(id: UserDto.Identifier) async -> UserDto?
    func update(users: [UserDto]) async

    func getSpendingCounterparties() async -> [SpendingsPreviewDto]?
    func updateSpendingCounterparties(_ counterparties: [SpendingsPreviewDto]) async
    func getSpendingsHistory(counterparty: UserDto.Identifier) async -> [IdentifiableDealDto]?
    func updateSpendingsHistory(counterparty: UserDto.Identifier, history: [IdentifiableDealDto]) async

    func getFriends(set: Set<FriendshipKindDto>) async -> [FriendshipKindDto: [UserDto]]?
    func update(friends: [FriendshipKindDto: [UserDto]], for set: Set<FriendshipKindDto>) async

    func close() async
    func invalidate() async
}
