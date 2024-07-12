import UIKit
import Combine
import Logging
import Domain
import DI

actor LoginModel {
    let subject = CurrentValueSubject<LoginState, Never>(LoginState(login: "", password: ""))
    let logger = Logger.shared.with(prefix: "[login]")

    private lazy var presenter = LoginPresenter(model: self, appRouter: appRouter)
    private let appRouter: AppRouter
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let validator: CredentialsValidator
    private var subscriptions = Set<AnyCancellable>()

    private weak var authModel: AuthModel?

    init(di: DIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        self.authUseCase = di.authUseCase()
        self.validator = CredentialsValidator(useCase: authUseCase)
        validator.loginVerdict
            .receive(on: RunLoop.main)
            .sink { verdictOrNil in
                self.subject.send(LoginState(state: self.subject.value, loginHint: .some(verdictOrNil.flatMap { verdict in
                    switch verdict {
                    case .tooShort(let minAllowedLength):
                        return String(format: "login_too_short".localized, minAllowedLength)
                    }
                })))
            }
            .store(in: &subscriptions)
        validator.passwordVerdict
            .receive(on: RunLoop.main)
            .sink { verdictOrNil in
                self.subject.send(LoginState(state: self.subject.value, passwordHint: .some(verdictOrNil.flatMap { verdict in
                    switch verdict {
                    case .tooShort(let minAllowedLength):
                        return String(format: "password_too_short".localized, minAllowedLength)
                    }
                })))
            }
            .store(in: &subscriptions)
    }

    func setAuthModel(_ model: AuthModel) {
        authModel = model
    }

    func start() async {
        await presenter.start()
    }

    @MainActor
    func updateLogin(_ login: String) {
        logI { "login updated: \(login)" }
        subject.send(LoginState(state: subject.value, login: login))
        validator.submit(login: login)
    }

    @MainActor
    func updatePassword(_ password: String) {
        logI { "password updated: \(password)" }
        subject.send(LoginState(state: subject.value, password: password))
        validator.submit(password: password)
    }

    @MainActor
    func confirmLogin() async {
        logI { "confirm login" }
        switch await authUseCase.validateLogin(subject.value.login) {
        case .success:
            await presenter.startPasswordEditing()
        case .failure(let reason):
            switch reason {
            case .tooShort(let minAllowedLength):
                await presenter.presentValidationError(
                    hint: String(format: "login_too_short".localized, minAllowedLength)
                )
            }
        }
    }

    func confirmPassword() async {
        logI { "confirm password" }
        switch await authUseCase.validatePassword(subject.value.password) {
        case .success:
            break
        case .failure(let reason):
            switch reason {
            case .tooShort(let minAllowedLength):
                await presenter.presentValidationError(
                    hint: String(format: "password_too_short".localized, minAllowedLength)
                )
            }
            return
        }
        let loginResult = await authUseCase.login(
            credentials: Credentials(
                login: subject.value.login,
                password: subject.value.password
            )
        )
        switch loginResult {
        case .success(let session):
            await authModel?.startAuthenticatedSession(di: session)
        case .failure(let reason):
            switch reason {
            case .incorrectCredentials(let error):
                await presenter.presentConfirmError(
                    hint: "wrong_credentials_hint".localized,
                    underlying: error
                )
            case .wrongFormat(let error):
                await presenter.presentConfirmError(
                    hint: "wrong_credentials_format_hint".localized,
                    underlying: error
                )
            case .noConnection(let error):
                await presenter.presentConfirmError(
                    hint: "no_connection_hint".localized,
                    underlying: error
                )
            case .other(let error):
                await presenter.presentConfirmError(
                    hint: "unknown_error_hint".localized,
                    underlying: error
                )
            }
        }
    }

    @MainActor
    func signup() async {
        logI { "signup" }
        await authModel?.signup.start()
    }
}

extension LoginModel: Loggable {}
