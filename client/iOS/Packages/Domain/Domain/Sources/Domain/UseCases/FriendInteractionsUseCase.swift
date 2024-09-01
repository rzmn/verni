import Foundation

public enum AcceptFriendRequestError: Error {
    case noSuchRequest(Error)
    case other(GeneralError)
}

public enum RejectFriendRequestError: Error {
    case noSuchRequest(Error)
    case other(GeneralError)
}

public enum SendFriendRequestError: Error {
    case alreadySent(Error)
    case haveIncoming(Error)
    case alreadyFriends(Error)
    case noSuchUser(Error)
    case other(GeneralError)
}

public enum RollbackFriendRequestError: Error {
    case noSuchRequest(Error)
    case other(GeneralError)
}

public enum UnfriendError: Error {
    case notAFriend(Error)
    case noSuchUser(Error)
    case other(GeneralError)
}

public protocol FriendInteractionsUseCase {
    func acceptFriendRequest(from user: User.ID) async throws(AcceptFriendRequestError)
    func rejectFriendRequest(from user: User.ID) async throws(RejectFriendRequestError)

    func sendFriendRequest(to user: User.ID) async throws(SendFriendRequestError)
    func rollbackFriendRequest(to user: User.ID) async throws(RollbackFriendRequestError)

    func unfriend(user: User.ID) async throws(UnfriendError)
}
