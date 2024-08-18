import AppBase
import Domain
import DI
import Combine

public actor UpdateDisplayNameFlow {
    @MainActor var subject: Published<UpdateDisplayNameState>.Publisher {
        viewModel.$state
    }

    private let router: AppRouter
    private let viewModel: UpdateDisplayNameViewModel
    private let profileEditing: ProfileEditingUseCase
    private let profileReposiroty: UsersRepository
    private lazy var presenter = UpdateDisplayNameFlowPresenter(router: router, flow: self)
    private var subscriptions = Set<AnyCancellable>()

    private var flowHandlers = [AnyHashable: AnyFlowEventHandler<FlowEvent>]()
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.profileReposiroty = di.usersRepository()
        self.profileEditing = di.profileEditingUseCase()
        self.viewModel = await UpdateDisplayNameViewModel()
    }
}

extension UpdateDisplayNameFlow: Flow {
    public enum TerminationEvent: Error {
        case canceledManually
    }

    public func perform() async -> Result<Profile, TerminationEvent> {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached { @MainActor in
                await self.presenter.presentDisplayNameEditing { [weak self] in
                    guard let self else { return }
                    await handle(result: .failure(.canceledManually))
                }
            }
        }
    }

    func confirmDisplayName() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.errorHaptic()
        }
        await presenter.presentLoading()
        switch await profileEditing.setDisplayName(state.displayName) {
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
        viewModel.displayName = displayName
    }

    private func handle(result: Result<Profile, TerminationEvent>) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        if case .failure(let error) = result, case .canceledManually = error {
        } else {
            await presenter.dismissDisplayNameEditing()
        }
        flowContinuation.resume(returning: result)
    }
}

extension UpdateDisplayNameFlow: FlowEvents {
    public enum FlowEvent {
        case profileUpdated(Profile)
    }

    public func addHandler<T>(handler: T) async where T : FlowEventHandler, FlowEvent == T.FlowEvent {
        flowHandlers[handler.id] = AnyFlowEventHandler(handler)
    }

    public func removeHandler<T>(handler: T) async where T : FlowEventHandler, FlowEvent == T.FlowEvent {
        flowHandlers[handler.id] = nil
    }
}
