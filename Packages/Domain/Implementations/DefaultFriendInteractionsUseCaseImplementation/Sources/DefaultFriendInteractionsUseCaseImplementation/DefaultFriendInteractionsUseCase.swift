import Domain
import Api

public actor DefaultFriendInteractionsUseCase {
    private let api: ApiProtocol

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension DefaultFriendInteractionsUseCase: FriendInteractionsUseCase {
    public func acceptFriendRequest(from user: User.Identifier) async throws(AcceptFriendRequestError) {
        do {
            try await api.run(method: Friends.AcceptRequest(sender: user))
        } catch {
            throw AcceptFriendRequestError(apiError: error)
        }
    }

    public func rejectFriendRequest(from user: User.Identifier) async throws(RejectFriendRequestError) {
        do {
            try await api.run(method: Friends.RejectRequest(sender: user))
        } catch {
            throw RejectFriendRequestError(apiError: error)
        }
    }

    public func sendFriendRequest(to user: User.Identifier) async throws(SendFriendRequestError) {
        do {
            try await api.run(method: Friends.SendRequest(target: user))
        } catch {
            throw SendFriendRequestError(apiError: error)
        }
    }

    public func rollbackFriendRequest(to user: User.Identifier) async throws(RollbackFriendRequestError) {
        do {
            try await api.run(method: Friends.RollbackRequest(target: user))
        } catch {
            throw RollbackFriendRequestError(apiError: error)
        }
    }

    public func unfriend(user: User.Identifier) async throws(UnfriendError) {
        do {
            try await api.run(method: Friends.Unfriend(target: user))
        } catch {
            throw UnfriendError(apiError: error)
        }
    }
}
