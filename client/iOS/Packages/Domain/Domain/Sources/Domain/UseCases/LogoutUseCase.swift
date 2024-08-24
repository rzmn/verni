import Combine

public enum LogoutReason {
    case refreshTokenFailed
}

public protocol LogoutUseCase {
    func logout() async

    var logoutIsRequired: AnyPublisher<LogoutReason, Never> { get }
}
