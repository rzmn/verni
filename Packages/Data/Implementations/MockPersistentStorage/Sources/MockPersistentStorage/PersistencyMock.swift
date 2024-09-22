import PersistentStorage
import DataTransferObjects

actor PersistencyMock: Persistency {
    var _userId: (@Sendable () async -> UserDto.Identifier)?
    var _getRefreshToken: (@Sendable () async -> String)?
    var _updateRefreshToken: (@Sendable (String) async -> Void)?
    var _getProfile: (@Sendable () async -> ProfileDto?)?
    var _updateProfile: (@Sendable (ProfileDto) async -> Void)?
    var _userWithID: (@Sendable (UserDto.Identifier) async -> UserDto?)?
    var _updateUsers: (@Sendable ([UserDto]) async -> Void)?
    var _getSpendingCounterparties: (@Sendable () async -> [SpendingsPreviewDto]?)?
    var _updateSpendingCounterparties: (@Sendable ([SpendingsPreviewDto]) async -> Void)?
    var _getSpendingsHistoryWithCounterparty: (@Sendable (UserDto.Identifier) async -> [IdentifiableDealDto]?)?
    var _updateSpendingsHistoryForCounterparty: (@Sendable (UserDto.Identifier, [IdentifiableDealDto]) async -> Void)?
    var _getFriendsWithKind: (@Sendable (Set<FriendshipKindDto>) async -> [FriendshipKindDto: [UserDto]]?)?
    var _updateFriendsForKind: (@Sendable ([FriendshipKindDto: [UserDto]], Set<FriendshipKindDto>) async -> Void)?
    var _close: (@Sendable () async -> Void)?
    var _invalidate: (@Sendable () async -> Void)?

    func userId() async -> UserDto.Identifier {
        await _userId!()
    }

    func getRefreshToken() async -> String {
        await _getRefreshToken!()
    }

    func update(refreshToken: String) async {
        await _updateRefreshToken!(refreshToken)
    }

    func getProfile() async -> ProfileDto? {
        await _getProfile!()
    }

    func update(profile: ProfileDto) async {
        await _updateProfile!(profile)
    }

    func user(id: UserDto.Identifier) async -> UserDto? {
        await _userWithID!(id)
    }

    func update(users: [UserDto]) async {
        await _updateUsers!(users)
    }

    func getSpendingCounterparties() async -> [SpendingsPreviewDto]? {
        await _getSpendingCounterparties!()
    }

    func updateSpendingCounterparties(_ counterparties: [SpendingsPreviewDto]) async {
        await _updateSpendingCounterparties!(counterparties)
    }

    func getSpendingsHistory(counterparty: UserDto.Identifier) async -> [IdentifiableDealDto]? {
        await _getSpendingsHistoryWithCounterparty!(counterparty)
    }

    func updateSpendingsHistory(counterparty: UserDto.Identifier, history: [IdentifiableDealDto]) async {
        await _updateSpendingsHistoryForCounterparty!(counterparty, history)
    }

    func getFriends(set: Set<FriendshipKindDto>) async -> [FriendshipKindDto: [UserDto]]? {
        await _getFriendsWithKind!(set)
    }

    func update(friends: [FriendshipKindDto: [UserDto]], for set: Set<FriendshipKindDto>) async {
        await _updateFriendsForKind!(friends, set)
    }

    func close() async {
        await _close!()
    }

    func invalidate() async {
        await _invalidate!()
    }
}
