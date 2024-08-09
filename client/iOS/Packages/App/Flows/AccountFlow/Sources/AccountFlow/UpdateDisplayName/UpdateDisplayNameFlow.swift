import AppBase
import Domain
import DI
import Combine

actor UpdateDisplayNameFlow {
    let subject = CurrentValueSubject<UpdateDisplayNameState, Never>(.initial)

    private let displayNameSubject = CurrentValueSubject<String, Never>("")

    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private let profileReposiroty: UsersRepository
    private lazy var presenter = UpdateDisplayNameFlowPresenter(router: router, flow: self)
    private var subscriptions = Set<AnyCancellable>()

    private var flowContinuation: Continuation?

    init(di: ActiveSessionDIContainer, router: AppRouter) {
        self.router = router
        self.profileReposiroty = di.usersRepository()
        self.profileEditing = di.profileEditingUseCase()
    }
}

extension UpdateDisplayNameFlow: Flow {
    enum FailureReason: Error {
        case canceledManually
    }

    func perform(willFinish: ((Result<Profile, FailureReason>) async -> Void)?) async -> Result<Profile, FailureReason> {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
            self.displayNameSubject
                .map {
                    UpdateDisplayNameState(displayName: $0, displayNameHint: nil)
                }
                .sink(receiveValue: self.subject.send)
                .store(in: &self.subscriptions)
            Task.detached { @MainActor in
                await self.presenter.presentDisplayNameEditing { [weak self] in
                    guard let self else { return }
                    await handle(result: .failure(.canceledManually))
                }
            }
        }
    }

    func confirmDisplayName() async {
        await presenter.presentLoading()
        switch await profileEditing.setDisplayName(subject.value.displayName) {
        case .success:
            await presenter.presentSuccess()
            switch await profileReposiroty.getHostInfo() {
            case .success(let profile):
                await handle(result: .success(profile))
            case .failure(let reason):
                switch reason {
                case .noConnection:
                    await presenter.presentNoConnection()
                case .notAuthorized:
                    await presenter.presentNotAuthorized()
                case .other(let error):
                    await presenter.presentInternalError(error)
                }
            }
        case .failure(let reason):
            switch reason {
            case .wrongFormat:
                await presenter.presentWrongFormat()
            case .other(let error):
                switch error {
                case .noConnection:
                    await presenter.presentNoConnection()
                case .notAuthorized:
                    await presenter.presentNotAuthorized()
                case .other(let error):
                    await presenter.presentInternalError(error)
                }
            }
        }
    }

    @MainActor
    func update(displayName: String) {
        displayNameSubject.send(displayName)
    }

    private func handle(result: Result<Profile, FailureReason>) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        await flowContinuation.willFinishHandler?(result)
        if case .failure(let error) = result, case .canceledManually = error {
        } else {
            await presenter.dismissDisplayNameEditing()
        }
        flowContinuation.continuation.resume(returning: result)
    }
}
