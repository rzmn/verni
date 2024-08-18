import DataTransferObjects

public protocol Persistency {
    func userId() async -> UserDto.ID

    func getRefreshToken() async -> String
    func update(refreshToken: String) async

    func getHostInfo() async -> ProfileDto?
    func update(hostInfo: ProfileDto) async
    func user(id: UserDto.ID) async -> UserDto?
    func update(users: [UserDto]) async

    func getSpendingCounterparties() async -> [SpendingsPreviewDto]?
    func updateSpendingCounterparties(_ counterparties: [SpendingsPreviewDto]) async
    func getSpendingsHistory(counterparty: UserDto.ID) async -> [IdentifiableDealDto]?
    func updateSpendingsHistory(counterparty: UserDto.ID, history: [IdentifiableDealDto]) async

    func getFriends(set: Set<FriendshipKindDto>) async -> [FriendshipKindDto : [UserDto]]?
    func storeFriends(_ friends: [FriendshipKindDto: [UserDto]]) async

    func close() async
    func invalidate() async
}
