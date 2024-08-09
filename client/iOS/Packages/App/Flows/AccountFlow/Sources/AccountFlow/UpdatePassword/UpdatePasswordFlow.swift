import AppBase
import Domain
import DI

actor UpdatePasswordFlow {
    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private lazy var presenter = UpdatePasswordFlowPresenter(router: router, flow: self)

    private var flowContinuation: Continuation?

    init(di: ActiveSessionDIContainer, router: AppRouter) {
        self.router = router
        self.profileEditing = di.profileEditingUseCase()
    }
}

extension UpdatePasswordFlow: Flow {
    enum FailureReason: Error {
        case canceledManually
    }

    func perform(willFinish: ((Result<Profile, FailureReason>) async -> Void)?) async -> Result<Profile, FailureReason> {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
            Task.detached { @MainActor in
                await self.presenter.presentPasswordEditing { [weak self] in
                    guard let self else { return }
                    await handle(result: .failure(.canceledManually))
                }
            }
        }
    }

    func updatePassword() async {
        
    }

    private func handle(result: Result<Profile, FailureReason>) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        await flowContinuation.willFinishHandler?(result)
        flowContinuation.continuation.resume(returning: result)
    }
}
