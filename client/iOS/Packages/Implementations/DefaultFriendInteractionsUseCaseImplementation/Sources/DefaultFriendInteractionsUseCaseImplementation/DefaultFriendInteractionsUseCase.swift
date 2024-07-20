import Domain
import Api

public class DefaultFriendInteractionsUseCase {
    private let api: Api

    public init(api: Api) {
        self.api = api
    }
}

extension DefaultFriendInteractionsUseCase: FriendInteractionsUseCase {
    public func acceptFriendRequest(from user: User.ID) async -> Result<Void, AcceptFriendRequestError> {
        let result = await api.acceptFriendRequest(from: user)
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(AcceptFriendRequestError(apiError: apiError))
        }
    }
    
    public func rejectFriendRequest(from user: User.ID) async -> Result<Void, RejectFriendRequestError> {
        let result = await api.rejectFriendRequest(from: user)
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(RejectFriendRequestError(apiError: apiError))
        }
    }
    
    public func sendFriendRequest(to user: User.ID) async -> Result<Void, SendFriendRequestError> {
        let result = await api.sendFriendRequest(to: user)
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(SendFriendRequestError(apiError: apiError))
        }
    }
    
    public func rollbackFriendRequest(to user: User.ID) async -> Result<Void, RollbackFriendRequestError> {
        let result = await api.rollbackFriendRequest(to: user)
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(RollbackFriendRequestError(apiError: apiError))
        }
    }
    
    public func unfriend(user: User.ID) async -> Result<Void, UnfriendError> {
        let result = await api.unfriend(uid: user)
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            return .failure(UnfriendError(apiError: apiError))
        }
    }
}
