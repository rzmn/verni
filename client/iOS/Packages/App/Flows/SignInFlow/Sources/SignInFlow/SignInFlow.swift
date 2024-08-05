import UIKit
import Domain
import DI
import AppBase
import Combine
import Security
internal import SignUpFlow
internal import DesignSystem
internal import ProgressHUD

public actor SignInFlow {
    let subject = CurrentValueSubject<SignInState, Never>(.initial)

    private let passwordSubject = CurrentValueSubject<String, Never>("")
    private let emailSubject = CurrentValueSubject<String, Never>("")
    private let emailHintSubject = CurrentValueSubject<String?, Never>(nil)

    private var subscriptions = Set<AnyCancellable>()

    private let signUpFlow: SignUpFlow
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let localEmailValidator: EmailValidationUseCase
    private let router: AppRouter

    private lazy var presenter = SignInFlowPresenter(router: router, flow: self)
    private var flowContinuation: CheckedContinuation<ActiveSessionDIContainer, Never>?

    public init(
        di: DIContainer,
        router: AppRouter
    ) async {
        authUseCase = di.authUseCase()
        localEmailValidator = di.appCommon().localEmailValidationUseCase()
        self.router = router
        self.signUpFlow = await SignUpFlow(di: di, router: router)
    }
}

extension SignInFlow: TabEmbedFlow {
    @MainActor public func viewController() async -> any Routable {
        await presenter.tabViewController
    }

    public func perform() async -> ActiveSessionDIContainer {
        await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
        }
    }

    func openSignIn() async {
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
        Publishers.CombineLatest3(emailSubject, passwordSubject, emailHintSubject)
            .receive(on: RunLoop.main)
            .map { value in
                SignInState(email: value.0, password: value.1, emailHint: value.2)
            }
            .removeDuplicates()
            .sink(receiveValue: subject.send)
            .store(in: &subscriptions)
        await presenter.presentSignIn()
    }

    func closeSignIn() async {
        subscriptions.removeAll()
        await presenter.dismissSignIn()
    }

    func signIn() async {
        let credentials = Credentials(
            email: subject.value.email,
            password: subject.value.password
        )
        await presenter.presentLoading()
        switch await authUseCase.login(credentials: credentials) {
        case .success(let session):
            guard let flowContinuation else {
                break
            }
            SecAddSharedWebCredential(
                "d5d29sfljfs1v5kq0382.apigw.yandexcloud.net" as CFString,
                credentials.email as CFString,
                credentials.password as CFString, { error in
                    print("\(error.debugDescription)")
                })
            self.flowContinuation = nil
            flowContinuation.resume(returning: session)
        case .failure(let failure):
            switch failure {
            case .incorrectCredentials:
                await presenter.presentIncorrectCredentials()
            case .wrongFormat:
                await presenter.presentWrongFormat()
            case .noConnection:
                await presenter.presentNoConnection()
            case .other(let error):
                await presenter.presentInternalError(error)
            }
        }
    }

    func createAccount() async {
        guard let session = await signUpFlow.perform() else {
            return
        }
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: session)
    }

    @MainActor func update(email: String) {
        emailSubject.send(email)
    }

    @MainActor func update(password: String) {
        passwordSubject.send(password)
    }
}
