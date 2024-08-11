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
    enum TerminationEvent: Error {
        case canceledManually
    }

    func perform(willFinish: ((Result<Profile, TerminationEvent>) async -> Void)?) async -> Result<Profile, TerminationEvent> {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
            self.displayNameSubject
                .map {
                    let displayNameHint: String?
                    if $0.isEmpty {
                        displayNameHint = nil
                    } else if $0.count < 4 {
                        displayNameHint = "display_name_invalid_lehght".localized
                    } else if !$0.allSatisfy({ $0.isNumber || $0.isLetter }) {
                        displayNameHint = "display_name_invalid_format".localized
                    } else {
                        displayNameHint = nil
                    }
                    return UpdateDisplayNameState(displayName: $0, displayNameHint: displayNameHint)
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
        guard subject.value.canConfirm else {
            return await presenter.errorHaptic()
        }
        await presenter.presentLoading()
        switch await profileEditing.setDisplayName(subject.value.displayName) {
        case .success:
            await presenter.successHaptic()
            await presenter.presentSuccess()
            switch await profileReposiroty.getHostInfo() {
            case .success(let profile):
                await handle(result: .success(profile))
            case .failure(let error):
                await presenter.presentGeneralError(error)
            }
        case .failure(let reason):
            switch reason {
            case .wrongFormat:
                await presenter.presentWrongFormat()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    @MainActor
    func update(displayName: String) {
        displayNameSubject.send(displayName)
    }

    private func handle(result: Result<Profile, TerminationEvent>) async {
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
