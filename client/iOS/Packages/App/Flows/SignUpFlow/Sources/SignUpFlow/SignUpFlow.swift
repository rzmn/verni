import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD

public actor SignUpFlow {
    let subject = CurrentValueSubject<SignUpState, Never>(.initial)

    private let passwordSubject = CurrentValueSubject<String, Never>("")
    private let passwordRepeatSubject = CurrentValueSubject<String, Never>("")
    private let emailSubject = CurrentValueSubject<String, Never>("")

    private let passwordHintSubject = CurrentValueSubject<String?, Never>(nil)
    private let passwordsMatchSubject = CurrentValueSubject<Bool?, Never>(nil)
    private let emailHintSubject = CurrentValueSubject<String?, Never>(nil)

    private var subscriptions = Set<AnyCancellable>()

    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let localEmailValidator: EmailValidationUseCase
    private let localPasswordValidator: PasswordValidationUseCase
    private let router: AppRouter
    private lazy var presenter = SignUpFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: DIContainer, router: AppRouter) async {
        self.router = router
        localEmailValidator = di.appCommon().localEmailValidationUseCase()
        localPasswordValidator = di.appCommon().passwordValidationUseCase()
        authUseCase = di.authUseCase()
    }
}

extension SignUpFlow: Flow {
    public func perform(willFinish: ((ActiveSessionDIContainer?) async -> Void)?) async -> ActiveSessionDIContainer? {
        emailSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .flatMap { email in
                Future<Result<Void, EmailValidationError>, Never>.init { promise in
                    guard !email.isEmpty else {
                        return promise(.success(.success(())))
                    }
                    Task {
                        promise(.success(await self.localEmailValidator.validateEmail(email)))
                    }
                }
            }.map { result -> String? in
                switch result {
                case .success:
                    return nil
                case .failure(let error):
                    switch error {
                    case .invalidFormat:
                        return "email_invalid_fmt".localized
                    case .alreadyTaken:
                        return "email_already_taken".localized
                    case .other:
                        assertionFailure("unexpected err during local validation")
                        return nil
                    }
                }
            }
            .sink(receiveValue: emailHintSubject.send)
            .store(in: &subscriptions)
        passwordSubject
            .flatMap { password in
                Future<Result<Void, PasswordValidationError>, Never>.init { promise in
                    guard !password.isEmpty else {
                        return promise(.success(.success(())))
                    }
                    Task {
                        promise(.success(await self.localPasswordValidator.validatePassword(password)))
                    }
                }
            }.map { result -> String? in
                switch result {
                case .success:
                    return nil
                case .failure(let error):
                    switch error {
                    case .tooShort(let minAllowedLength):
                        return String(format: "password_too_short".localized, minAllowedLength)
                    case .invalidFormat:
                        return "password_invalid_format".localized
                    }
                }
            }
            .sink(receiveValue: passwordHintSubject.send)
            .store(in: &subscriptions)
        Publishers.CombineLatest(passwordSubject, passwordRepeatSubject)
            .map { value -> Bool? in
                let (password, passwordRepeat) = value
                guard !password.isEmpty && !passwordRepeat.isEmpty else {
                    return nil
                }
                return password == passwordRepeat
            }
            .sink(receiveValue: passwordsMatchSubject.send)
            .store(in: &subscriptions)

        let credentials = Publishers.CombineLatest3(emailSubject, passwordSubject, passwordRepeatSubject)
        let hints = Publishers.CombineLatest3(emailHintSubject, passwordHintSubject, passwordsMatchSubject)
        Publishers.CombineLatest(credentials, hints)
            .map { value in
                let (credentials, hints) = value
                let (email, password, passwordRepeat) = credentials
                let (emailHint, passwordHint, passwordsMatchHint) = hints
                return SignUpState(
                    email: email,
                    password: password,
                    passwordConfirmation: passwordRepeat,
                    emailHint: emailHint,
                    passwordHint: passwordHint,
                    passwordConfirmationHint: {
                        guard let passwordsMatchHint else {
                            return nil
                        }
                        if !passwordsMatchHint {
                            return "login_pwd_didnt_match".localized
                        } else {
                            return nil
                        }
                    }()
                )
            }
            .removeDuplicates()
            .sink(receiveValue: subject.send)
            .store(in: &subscriptions)


        await presenter.presentSignUp()
        return await withCheckedContinuation { continuation in
            self.flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
        }
    }

    func signIn() async {
        guard subject.value.canConfirm else {
            return await presenter.errorHaptic()
        }
        let credentials = Credentials(
            email: subject.value.email,
            password: subject.value.password
        )
        await presenter.presentLoading()
        switch await authUseCase.signup(credentials: credentials) {
        case .success(let session):
            guard let flowContinuation else {
                break
            }
            self.flowContinuation = nil
            await flowContinuation.willFinishHandler?(session)
            flowContinuation.continuation.resume(returning: session)
        case .failure(let failure):
            await presenter.errorHaptic()
            switch failure {
            case .alreadyTaken:
                await presenter.presentAlreadyTaken()
            case .wrongFormat:
                await presenter.presentWrongFormat()
            case .noConnection(_):
                await presenter.presentNoConnection()
            case .other(let error):
                await presenter.presentInternalError(error)
            }
        }
    }

    @MainActor func update(email: String) {
        emailSubject.send(email)
    }

    @MainActor func update(password: String) {
        passwordSubject.send(password)
    }

    @MainActor func update(passwordRepeat: String) {
        passwordRepeatSubject.send(passwordRepeat)
    }
}
