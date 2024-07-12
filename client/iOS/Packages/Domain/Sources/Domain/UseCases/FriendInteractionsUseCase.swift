import Foundation

public enum AcceptFriendRequestError: Error {
    case noSuchRequest(Error)
    case other(RepositoryError)
}

public enum RejectFriendRequestError: Error {
    case noSuchRequest(Error)
    case other(RepositoryError)
}

public enum SendFriendRequestError: Error {
    case alreadySent(Error)
    case haveIncoming(Error)
    case alreadyFriends(Error)
    case noSuchUser(Error)
    case other(RepositoryError)
}

public enum RollbackFriendRequestError: Error {
    case noSuchRequest(Error)
    case other(RepositoryError)
}

public enum UnfriendError: Error {
    case notAFriend(Error)
    case noSuchUser(Error)
    case other(RepositoryError)
}

public protocol FriendInteractionsUseCase {
    func acceptFriendRequest(from user: User.ID) async -> Result<Void, AcceptFriendRequestError>
    func rejectFriendRequest(from user: User.ID) async -> Result<Void, RejectFriendRequestError>
    
    func sendFriendRequest(to user: User.ID) async -> Result<Void, SendFriendRequestError>
    func rollbackFriendRequest(to user: User.ID) async -> Result<Void, RollbackFriendRequestError>

    func unfriend(user: User.ID) async -> Result<Void, UnfriendError>
}
