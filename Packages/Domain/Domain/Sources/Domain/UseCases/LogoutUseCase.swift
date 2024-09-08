import Combine

public enum LogoutReason: Sendable {
    case refreshTokenFailed
}

public protocol LogoutUseCase: Sendable {
    func logout() async

    var didLogoutPublisher: AnyPublisher<LogoutReason, Never> { get async }
}
