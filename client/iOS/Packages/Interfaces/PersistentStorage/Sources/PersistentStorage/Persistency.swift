import Domain

public protocol Persistency {
    func getRefreshToken() async -> String
    func update(refreshToken: String) async

    func getHostInfo() async -> User?
    func user(id: User.ID) async -> User?
    func update(users: [User]) async

    func getSpendingCounterparties() async -> [SpendingsPreview]?
    func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async
    func getSpendingsHistory(counterparty: User.ID) async -> [IdentifiableSpending]?
    func updateSpendingsHistory(counterparty: User.ID, history: [IdentifiableSpending]) async

    func getFriends(set: Set<FriendshipKind>) async -> [FriendshipKind : [User]]?
    func storeFriends(_ friends: [FriendshipKind : [User]]) async

    func close() async
    func invalidate() async
}
