import AppBase
import Combine
import Domain
import DI

actor UpdateEmailFlow {
    let subject: CurrentValueSubject<UpdateEmailState, Never>

    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private lazy var presenter = UpdateEmailFlowPresenter(router: router, flow: self)

    private var flowContinuation: Continuation?

    init(di: ActiveSessionDIContainer, router: AppRouter, profile: Profile) {
        self.router = router
        self.profileEditing = di.profileEditingUseCase()
        subject = CurrentValueSubject(
            UpdateEmailState(
                email: profile.email,
                confirmation: profile.isEmailVerified ? .confirmed : .uncorfirmed(currentCode: "")
            )
        )
    }
}

extension UpdateEmailFlow: Flow {
    enum FailureReason: Error {
        case canceledManually
    }

    func perform(willFinish: ((Result<Profile, FailureReason>) async -> Void)?) async -> Result<Profile, FailureReason> {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
            Task.detached { @MainActor in
                await self.presenter.presentEmailEditing { [weak self] in
                    guard let self else { return }
                    await handle(result: .failure(.canceledManually))
                }
            }
        }
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
