import Foundation
import Combine
import Logging
import Domain
import DI

actor SignupModel {
    let subject = CurrentValueSubject<SignupState, Never>(SignupState(login: "", password: ""))
    let logger = Logger.shared.with(prefix: "[signup]")

    private lazy var presenter = SignupPresenter(model: self, appRouter: appRouter)
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let appRouter: AppRouter
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
                self.subject.send(SignupState(state: self.subject.value, loginHint: .some(verdictOrNil.flatMap { verdict in
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
                self.subject.send(SignupState(state: self.subject.value, passwordHint: .some(verdictOrNil.flatMap { verdict in
                    switch verdict {
                    case .tooShort(let minAllowedLength):
                        return String(format: "password_too_short".localized, minAllowedLength)
                    }
                })))
            }
            .store(in: &subscriptions)
    }

    func setAuthModel(authModel: AuthModel) {
        self.authModel = authModel
    }

    @MainActor
    func start() async {
        await presenter.start()
    }

    @MainActor
    func updateLogin(_ login: String) {
        logI { "login updated: \(login)" }
        subject.send(SignupState(state: subject.value, login: login))
    }

    @MainActor
    func updatePassword(_ password: String) {
        logI { "password updated: \(password)" }
        subject.send(SignupState(state: subject.value, password: password))
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

    @MainActor
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
        let loginResult = await authUseCase.signup(
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
            case .alreadyTaken(let error):
                await presenter.presentConfirmError(
                    hint: "already_taken_hint".localized,
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
}

extension SignupModel: Loggable {}
