import Domain
import PersistentStorage
import Combine
internal import ApiDomainConvenience
internal import DataTransferObjects

private actor LoggedOutHandler {
    private var loggedOut = false

    func allowLogout() -> Bool {
        let allow = !loggedOut
        loggedOut = true
        return allow
    }
}

public actor DefaultLogoutUseCase {
    private let didLogoutSubject = PassthroughSubject<LogoutReason, Never>()
    private let persistency: Persistency
    private var subscriptions = Set<AnyCancellable>()
    private var loggedOutHandler = LoggedOutHandler()

    public init(
        persistency: Persistency,
        shouldLogout: AnyPublisher<LogoutReason, Never>
    ) async {
        self.persistency = persistency
        shouldLogout
            .flatMap { reason -> Future<LogoutReason?, Never> in
                Future { promise in
                    Task.detached {
                        if await self.doLogout() {
                            promise(.success(reason))
                        } else {
                            promise(.success(nil))
                        }
                    }
                }
            }
            .compactMap { $0 }
            .sink(receiveValue: didLogoutSubject.send)
            .store(in: &subscriptions)
    }
}

extension DefaultLogoutUseCase: LogoutUseCase {
    public var didLogoutPublisher: AnyPublisher<LogoutReason, Never> {
        didLogoutSubject.eraseToAnyPublisher()
    }

    public func logout() async {
        await doLogout()
    }
}

extension DefaultLogoutUseCase {
    @discardableResult
    private func doLogout() async -> Bool {
        guard await loggedOutHandler.allowLogout() else {
            return false
        }
        Task.detached {
            await self.persistency.invalidate()
        }
        return true
    }
}
