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
    private lazy var presenter = UpdateDisplayNameFlowPresenter(router: router, flow: self)
    private var subscriptions = Set<AnyCancellable>()

    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.profileEditing = di.profileEditingUseCase()
        self.viewModel = await UpdateDisplayNameViewModel()
    }
}

// MARK: - Flow

extension UpdateDisplayNameFlow: Flow {
    public enum TerminationEvent {
        case canceled
        case successfullySet
    }

    public func perform() async -> TerminationEvent {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached {
                await self.startFlow()
            }
        }
    }

    private func startFlow() async {
        await self.presenter.presentDisplayNameEditing { [weak self] in
            guard let self else { return }
            await handle(event: .canceled)
        }
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        if case .canceled = event {
        } else {
            await presenter.dismissDisplayNameEditing()
        }
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension UpdateDisplayNameFlow {
    @MainActor func update(displayName: String) {
        viewModel.displayName = displayName
    }

    @MainActor func confirmDisplayName() {
        Task.detached {
            await self.doConfirmDisplayName()
        }
    }
}

// MARK: - Private

extension UpdateDisplayNameFlow {
    private func doConfirmDisplayName() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.errorHaptic()
        }
        await presenter.presentLoading()
        switch await profileEditing.setDisplayName(state.displayName) {
        case .success:
            await presenter.successHaptic()
            await presenter.presentSuccess()
            await handle(event: .successfullySet)
        case .failure(let reason):
            switch reason {
            case .wrongFormat:
                await presenter.presentWrongFormat()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }
}
