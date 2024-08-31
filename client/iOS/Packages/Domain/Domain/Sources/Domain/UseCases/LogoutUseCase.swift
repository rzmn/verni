import Combine

public enum LogoutReason {
    case refreshTokenFailed
}

public protocol LogoutUseCase {
    func logout() async

    var didLogoutPublisher: AnyPublisher<LogoutReason, Never> { get async }
}
