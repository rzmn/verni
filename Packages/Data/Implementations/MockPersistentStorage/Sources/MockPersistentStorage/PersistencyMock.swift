import PersistentStorage
import DataTransferObjects

actor PersistencyMock: Persistency {
    var userIdBlock: (@Sendable () async -> UserDto.Identifier)?
    var getRefreshTokenBlock: (@Sendable () async -> String)?
    var updateRefreshTokenBlock: (@Sendable (String) async -> Void)?
    var getProfileBlock: (@Sendable () async -> ProfileDto?)?
    var updateProfileBlock: (@Sendable (ProfileDto) async -> Void)?
    var userWithIDBlock: (@Sendable (UserDto.Identifier) async -> UserDto?)?
    var updateUsersBlock: (@Sendable ([UserDto]) async -> Void)?
    var getSpendingCounterpartiesBlock: (@Sendable () async -> [SpendingsPreviewDto]?)?
    var updateSpendingCounterpartiesBlock: (@Sendable ([SpendingsPreviewDto]) async -> Void)?
    var getSpendingsHistoryBlock: (@Sendable (UserDto.Identifier) async -> [IdentifiableDealDto]?)?
    var updateSpendingsHistoryBlock: (@Sendable (UserDto.Identifier, [IdentifiableDealDto]) async -> Void)?
    var getFriendsWithKindBlock: (@Sendable (Set<FriendshipKindDto>) async -> [FriendshipKindDto: [UserDto]]?)?
    var updateFriendsForKindBlock: (@Sendable ([FriendshipKindDto: [UserDto]], Set<FriendshipKindDto>) async -> Void)?
    var closeBlock: (@Sendable () async -> Void)?
    var invalidateBlock: (@Sendable () async -> Void)?

    func userId() async -> UserDto.Identifier {
        guard let userIdBlock else {
            fatalError("not implemented")
        }
        return await userIdBlock()
    }

    func getRefreshToken() async -> String {
        guard let getRefreshTokenBlock else {
            fatalError("not implemented")
        }
        return await getRefreshTokenBlock()
    }

    func update(refreshToken: String) async {
        guard let updateRefreshTokenBlock else {
            fatalError("not implemented")
        }
        return await updateRefreshTokenBlock(refreshToken)
    }

    func getProfile() async -> ProfileDto? {
        guard let getProfileBlock else {
            fatalError("not implemented")
        }
        return await getProfileBlock()
    }

    func update(profile: ProfileDto) async {
        guard let updateProfileBlock else {
            fatalError("not implemented")
        }
        return await updateProfileBlock(profile)
    }

    func user(id: UserDto.Identifier) async -> UserDto? {
        guard let userWithIDBlock else {
            fatalError("not implemented")
        }
        return await userWithIDBlock(id)
    }

    func update(users: [UserDto]) async {
        guard let updateUsersBlock else {
            fatalError("not implemented")
        }
        return await updateUsersBlock(users)
    }

    func getSpendingCounterparties() async -> [SpendingsPreviewDto]? {
        guard let getSpendingCounterpartiesBlock else {
            fatalError("not implemented")
        }
        return await getSpendingCounterpartiesBlock()
    }

    func updateSpendingCounterparties(_ counterparties: [SpendingsPreviewDto]) async {
        guard let updateSpendingCounterpartiesBlock else {
            fatalError("not implemented")
        }
        return await updateSpendingCounterpartiesBlock(counterparties)
    }

    func getSpendingsHistory(counterparty: UserDto.Identifier) async -> [IdentifiableDealDto]? {
        guard let getSpendingsHistoryBlock else {
            fatalError("not implemented")
        }
        return await getSpendingsHistoryBlock(counterparty)
    }

    func updateSpendingsHistory(counterparty: UserDto.Identifier, history: [IdentifiableDealDto]) async {
        guard let updateSpendingsHistoryBlock else {
            fatalError("not implemented")
        }
        return await updateSpendingsHistoryBlock(counterparty, history)
    }

    func getFriends(set: Set<FriendshipKindDto>) async -> [FriendshipKindDto: [UserDto]]? {
        guard let getFriendsWithKindBlock else {
            fatalError("not implemented")
        }
        return await getFriendsWithKindBlock(set)
    }

    func update(friends: [FriendshipKindDto: [UserDto]], for set: Set<FriendshipKindDto>) async {
        guard let updateFriendsForKindBlock else {
            fatalError("not implemented")
        }
        return await updateFriendsForKindBlock(friends, set)
    }

    func close() async {
        guard let closeBlock else {
            fatalError("not implemented")
        }
        return await closeBlock()
    }

    func invalidate() async {
        guard let invalidateBlock else {
            fatalError("not implemented")
        }
        return await invalidateBlock()
    }
}
