import Domain
import Api

public class DefaultFriendInteractionsUseCase {
    private let api: ApiProtocol

    public init(api: ApiProtocol) {
        self.api = api
    }
}

extension DefaultFriendInteractionsUseCase: FriendInteractionsUseCase {
    public func acceptFriendRequest(from user: User.ID) async -> Result<Void, AcceptFriendRequestError> {
        do {
            return .success(try await api.run(method: Friends.AcceptRequest(sender: user)))
        } catch {
            return .failure(AcceptFriendRequestError(apiError: error))
        }
    }
    
    public func rejectFriendRequest(from user: User.ID) async -> Result<Void, RejectFriendRequestError> {
        do {
            return .success(try await api.run(method: Friends.RejectRequest(sender: user)))
        } catch {
            return .failure(RejectFriendRequestError(apiError: error))
        }
    }
    
    public func sendFriendRequest(to user: User.ID) async -> Result<Void, SendFriendRequestError> {
        do {
            return .success(try await api.run(method: Friends.SendRequest(target: user)))
        } catch {
            return .failure(SendFriendRequestError(apiError: error))
        }
    }
    
    public func rollbackFriendRequest(to user: User.ID) async -> Result<Void, RollbackFriendRequestError> {
        do {
            return .success(try await api.run(method: Friends.RollbackRequest(target: user)))
        } catch {
            return .failure(RollbackFriendRequestError(apiError: error))
        }
    }
    
    public func unfriend(user: User.ID) async -> Result<Void, UnfriendError> {
        do {
            return .success(try await api.run(method: Friends.Unfriend(target: user)))
        } catch {
            return .failure(UnfriendError(apiError: error))
        }
    }
}
