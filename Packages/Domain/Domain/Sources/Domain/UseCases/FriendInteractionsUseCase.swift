import Foundation

public enum AcceptFriendRequestError: Error, Sendable {
    case noSuchRequest(Error)
    case other(GeneralError)
}

public enum RejectFriendRequestError: Error, Sendable {
    case noSuchRequest(Error)
    case other(GeneralError)
}

public enum SendFriendRequestError: Error, Sendable {
    case alreadySent(Error)
    case haveIncoming(Error)
    case alreadyFriends(Error)
    case noSuchUser(Error)
    case other(GeneralError)
}

public enum RollbackFriendRequestError: Error, Sendable {
    case noSuchRequest(Error)
    case other(GeneralError)
}

public enum UnfriendError: Error, Sendable {
    case notAFriend(Error)
    case noSuchUser(Error)
    case other(GeneralError)
}

public protocol FriendInteractionsUseCase: Sendable {
    func acceptFriendRequest(from user: User.Identifier) async throws(AcceptFriendRequestError)
    func rejectFriendRequest(from user: User.Identifier) async throws(RejectFriendRequestError)

    func sendFriendRequest(to user: User.Identifier) async throws(SendFriendRequestError)
    func rollbackFriendRequest(to user: User.Identifier) async throws(RollbackFriendRequestError)

    func unfriend(user: User.Identifier) async throws(UnfriendError)
}
