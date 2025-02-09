import AsyncExtensions

public enum LogoutReason: Sendable {
    case refreshTokenFailed
}

public protocol LogoutUseCase: Sendable {
    func logout() async

    var didLogoutEventSource: any EventSource<LogoutReason> { get async }
}
