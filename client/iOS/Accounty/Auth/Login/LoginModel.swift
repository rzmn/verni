import UIKit
import Combine
import Logging
import Domain
import DI

actor LoginModel {
    let subject = CurrentValueSubject<LoginState, Never>(LoginState(login: "", password: ""))
    let logger = Logger.shared.with(prefix: "[login]")

    private lazy var presenter = LoginPresenter(model: self, appRouter: appRouter)
    private let signupModel: SignupModel
    private let appRouter: AppRouter
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let validator: CredentialsValidator
    private var subscriptions = Set<AnyCancellable>()

    init(di: DIContainer, appRouter: AppRouter) async {
        self.signupModel = await SignupModel(di: di, appRouter: appRouter)
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

    
    private var flowContinuation: CheckedContinuation<ActiveSessionDIContainer, Never>?
    private func updateFlowContinuation(_ continuation: CheckedContinuation<ActiveSessionDIContainer, Never>?) {
        flowContinuation = continuation
    }

    func performFlow() async -> ActiveSessionDIContainer {
        if flowContinuation != nil {
            assertionFailure("login flow is already running")
        }
        return await withCheckedContinuation { continuation in
            Task {
                updateFlowContinuation(continuation)
                await presenter.start()
            }
        }
    }

    func updateLogin(_ login: String) {
        logI { "login updated: \(login)" }
        subject.send(LoginState(state: subject.value, login: login))
        validator.submit(login: login)
    }

    func updatePassword(_ password: String) {
        logI { "password updated: \(password)" }
        subject.send(LoginState(state: subject.value, password: password))
        validator.submit(password: password)
    }

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
            guard let flowContinuation else {
                assertionFailure("login flow was finished after cancellation")
                break
            }
            self.flowContinuation = nil
            flowContinuation.resume(returning: session)
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

    func signup() async {
        logI { "signup" }
        switch await signupModel.performFlow() {
        case .signedUp(let session):
            guard let flowContinuation else {
                assertionFailure("signup flow was finished when login flow is finished")
                break
            }
            self.flowContinuation = nil
            flowContinuation.resume(returning: session)
        case .canceled:
            break
        }
    }
}

extension LoginModel: Loggable {}
