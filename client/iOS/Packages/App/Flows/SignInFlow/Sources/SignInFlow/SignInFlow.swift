import UIKit
import Domain
import DI
import AppBase
import Combine
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
    private let passwordValidator: PasswordValidationUseCase
    private let saveCredentials: SaveCredendialsUseCase
    private let router: AppRouter

    private lazy var presenter = SignInFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(
        di: DIContainer,
        router: AppRouter
    ) async {
        authUseCase = di.authUseCase()
        localEmailValidator = di.appCommon().localEmailValidationUseCase()
        passwordValidator = di.appCommon().localPasswordValidationUseCase()
        saveCredentials = di.appCommon().saveCredentials()
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
        await presenter.submitHaptic()
        emailSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .map(localEmailValidator.validateEmail)
            .map { result -> String? in
                switch result {
                case .success:
                    return nil
                case .failure(let error):
                    return error.message
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
        guard subject.value.canConfirm else {
            return await presenter.errorHaptic()
        }
        let credentials = Credentials(
            email: subject.value.email,
            password: subject.value.password
        )
        await presenter.presentLoading()
        switch await authUseCase.login(credentials: credentials) {
        case .success(let session):
            await saveCredentials.save(email: credentials.email, password: credentials.password)
            await handle(session: session)
        case .failure(let failure):
            await presenter.errorHaptic()
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
        await presenter.submitHaptic()
        guard let session = await signUpFlow.perform() else {
            return
        }
        await handle(session: session)
    }

    @MainActor func update(email: String) {
        emailSubject.send(email)
    }

    @MainActor func update(password: String) {
        passwordSubject.send(password)
    }

    private func handle(session: ActiveSessionDIContainer) async {
        guard let flowContinuation else {
            return
        }
        _ = await session.usersRepository().getHostInfo()
        self.flowContinuation = nil
        flowContinuation.resume(returning: session)
    }
}
