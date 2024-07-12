import Combine
import Foundation
import Domain
import Base

class CredentialsValidator {
    lazy var loginVerdict = loginSubject
        .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
        .flatMap { login in
            Future<Result<Void, ValidationFailureReason>, Never>.init { promise in
                if login.isEmpty {
                    promise(.success(.success(())))
                } else {
                    Task {
                        promise(.success(await self.useCase.validateLogin(login)))
                    }
                }
            }
        }
        .map(\.failure)
        .eraseToAnyPublisher()
    lazy var passwordVerdict = passwordSubject
        .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
        .flatMap { password in
            Future<Result<Void, ValidationFailureReason>, Never>.init { promise in
                if password.isEmpty {
                    promise(.success(.success(())))
                } else {
                    Task {
                        promise(.success(await self.useCase.validatePassword(password)))
                    }
                }
            }
        }
        .map(\.failure)
        .eraseToAnyPublisher()

    private let loginSubject = PassthroughSubject<String, Never>()
    private let passwordSubject = PassthroughSubject<String, Never>()
    private let useCase: any AuthUseCase

    init(useCase: any AuthUseCase) {
        self.useCase = useCase
    }

    func submit(login: String) {
        loginSubject.send(login)
    }

    func submit(password: String) {
        passwordSubject.send(password)
    }
}
