import AppBase
import Domain
import DI
import Combine
import AsyncExtensions

public actor UpdateDisplayNameFlow {
    private lazy var presenter = AsyncLazyObject {
        UpdateDisplayNamePresenter(
            router: self.router,
            actions: await MainActor.run {
                self.makeActions()
            }
        )
    }
    private let router: AppRouter
    private let viewModel: UpdateDisplayNameViewModel
    private let profileEditing: ProfileEditingUseCase
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
    public enum TerminationEvent: Sendable {
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
        await presenter.value.presentDisplayNameEditing { [weak self] in
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
            await presenter.value.dismissDisplayNameEditing()
        }
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension UpdateDisplayNameFlow {
    @MainActor private func makeActions() -> UpdateDisplayNameViewActions {
        UpdateDisplayNameViewActions(state: viewModel.$state) { [weak self] action in
            guard let self else { return }
            switch action {
            case .onDisplayNameTextChanged(let text):
                viewModel.displayName = text
            case .onConfirmTap:
                Task.detached {
                    await self.confirmDisplayName()
                }
            }
        }
    }
}

// MARK: - Private

extension UpdateDisplayNameFlow {
    private func confirmDisplayName() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.value.errorHaptic()
        }
        await presenter.value.presentLoading()
        do {
            try await profileEditing.setDisplayName(state.displayName)
            await presenter.value.successHaptic()
            await presenter.value.presentSuccess()
            await handle(event: .successfullySet)
        } catch {
            switch error {
            case .wrongFormat:
                await presenter.value.presentWrongFormat()
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
    }
}
