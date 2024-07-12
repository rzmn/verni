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
        let error: ApiError
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            error = apiError
        }
        let errorCode: ApiErrorCode
        switch error {
        case .noConnection(let error):
            return .failure(.other(.noConnection(error)))
        case .internalError(let error):
            return .failure(.other(.other(error)))
        case .api(let apiErrorCode, _):
            errorCode = apiErrorCode
        }
        switch errorCode {
        case .noSuchRequest:
            return .failure(.noSuchRequest(error))
        case .tokenExpired:
            return .failure(.other(.notAuthorized(error)))
        default:
            return .failure(.other(.other(error)))
        }
    }
    
    public func rejectFriendRequest(from user: User.ID) async -> Result<Void, RejectFriendRequestError> {
        let result = await api.rejectFriendRequest(from: user)
        let error: ApiError
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            error = apiError
        }
        let errorCode: ApiErrorCode
        switch error {
        case .noConnection(let error):
            return .failure(.other(.noConnection(error)))
        case .internalError(let error):
            return .failure(.other(.other(error)))
        case .api(let apiErrorCode, _):
            errorCode = apiErrorCode
        }
        switch errorCode {
        case .noSuchRequest:
            return .failure(.noSuchRequest(error))
        case .tokenExpired:
            return .failure(.other(.notAuthorized(error)))
        default:
            return .failure(.other(.other(error)))
        }
    }
    
    public func sendFriendRequest(to user: User.ID) async -> Result<Void, SendFriendRequestError> {
        let result = await api.sendFriendRequest(to: user)
        let error: ApiError
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            error = apiError
        }
        let errorCode: ApiErrorCode
        switch error {
        case .noConnection(let error):
            return .failure(.other(.noConnection(error)))
        case .internalError(let error):
            return .failure(.other(.other(error)))
        case .api(let apiErrorCode, _):
            errorCode = apiErrorCode
        }
        switch errorCode {
        case .alreadySend:
            return .failure(.alreadySent(error))
        case .haveIncomingRequest:
            return .failure(.haveIncoming(error))
        case .alreadyFriends:
            return .failure(.alreadyFriends(error))
        case .noSuchUser:
            return .failure(.noSuchUser(error))
        case .tokenExpired:
            return .failure(.other(.notAuthorized(error)))
        default:
            return .failure(.other(.other(error)))
        }
    }
    
    public func rollbackFriendRequest(to user: User.ID) async -> Result<Void, RollbackFriendRequestError> {
        let result = await api.rollbackFriendRequest(to: user)
        let error: ApiError
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            error = apiError
        }
        let errorCode: ApiErrorCode
        switch error {
        case .noConnection(let error):
            return .failure(.other(.noConnection(error)))
        case .internalError(let error):
            return .failure(.other(.other(error)))
        case .api(let apiErrorCode, _):
            errorCode = apiErrorCode
        }
        switch errorCode {
        case .noSuchRequest:
            return .failure(.noSuchRequest(error))
        case .tokenExpired:
            return .failure(.other(.notAuthorized(error)))
        default:
            return .failure(.other(.other(error)))
        }
    }
    
    public func unfriend(user: User.ID) async -> Result<Void, UnfriendError> {
        let result = await api.unfriend(uid: user)
        let error: ApiError
        switch result {
        case .success:
            return .success(())
        case .failure(let apiError):
            error = apiError
        }
        let errorCode: ApiErrorCode
        switch error {
        case .noConnection(let error):
            return .failure(.other(.noConnection(error)))
        case .internalError(let error):
            return .failure(.other(.other(error)))
        case .api(let apiErrorCode, _):
            errorCode = apiErrorCode
        }
        switch errorCode {
        case .notAFriend:
            return .failure(.notAFriend(error))
        case .noSuchUser:
            return .failure(.noSuchUser(error))
        case .tokenExpired:
            return .failure(.other(.notAuthorized(error)))
        default:
            return .failure(.other(.other(error)))
        }
    }
}
