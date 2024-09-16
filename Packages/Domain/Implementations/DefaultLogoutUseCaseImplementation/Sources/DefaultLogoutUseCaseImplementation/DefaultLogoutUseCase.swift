import Domain
import PersistentStorage
import Combine
import Base
import AsyncExtensions
internal import ApiDomainConvenience
internal import DataTransferObjects

public actor DefaultLogoutUseCase {
    private let didLogoutSubject = PassthroughSubject<LogoutReason, Never>()
    private let persistency: Persistency
    private let taskFactory: TaskFactory
    private var subscriptions = Set<AnyCancellable>()
    private var loggedOutHandler = LoggedOutHandler()

    public init(
        persistency: Persistency,
        shouldLogout: AnyPublisher<LogoutReason, Never>,
        taskFactory: TaskFactory
    ) async {
        self.persistency = persistency
        self.taskFactory = taskFactory
        typealias Promise = @Sendable (Result<LogoutReason?, Never>) -> Void
        let sendablePromise: @Sendable (LogoutReason, @escaping Promise) -> Void = { reason, promise in
            print("[debug] receive \(reason)")
            self.taskFactory.task {
                if await self.doLogout() {
                    promise(.success(reason))
                } else {
                    promise(.success(nil))
                }
            }
        }
        shouldLogout
            .flatMap { reason -> Future<LogoutReason?, Never> in
                Future { [sendablePromise] promise in
                    // https://forums.swift.org/t/await-non-sendable-callback-violates-actor-isolation/69354
                    print("[debug] future \(reason) start")
                    nonisolated(unsafe) let promise = promise
                    sendablePromise(reason) {
                        promise($0)
                        print("[debug] future \(reason) finished")
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
            print("[debug] doLogout: skip")
            return false
        }
        print("[debug] doLogout: ok")
        taskFactory.task {
            await self.persistency.invalidate()
            print("[debug] doLogout: invalidated")
        }
        return true
    }
}
