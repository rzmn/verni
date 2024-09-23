import AppBase
import Combine
import Domain
import DI
import AsyncExtensions

public actor UpdatePasswordFlow {
    private lazy var presenter = AsyncLazyObject {
        UpdatePasswordPresenter(
            router: self.router,
            actions: await MainActor.run {
                self.makeActions()
            }
        )
    }
    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private let viewModel: UpdatePasswordViewModel
    private var subscriptions = Set<AnyCancellable>()

    private let saveCredentials: SaveCredendialsUseCase
    private let profile: Profile

    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter, profile: Profile) async {
        self.router = router
        self.profile = profile
        self.saveCredentials = di.appCommon.saveCredentialsUseCase
        self.profileEditing = di.profileEditingUseCase()
        viewModel = await UpdatePasswordViewModel(
            passwordValidation: di.appCommon.localPasswordValidationUseCase
        )
    }
}

// MARK: - Flow

extension UpdatePasswordFlow: Flow {
    public enum TerminationEvent: Sendable {
        case canceled
        case successfullySet
    }

    public func perform() async -> TerminationEvent {
        await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached {
                await self.startFlow()
            }
        }
    }

    private func startFlow() async {
        await presenter.value.presentPasswordEditing { [weak self] in
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
            await presenter.value.cancelPasswordEditing()
        }
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension UpdatePasswordFlow {
    @MainActor private func makeActions() -> UpdatePasswordViewActions {
        UpdatePasswordViewActions(state: viewModel.$state) { [weak self] action in
            guard let self else { return }
            switch action {
            case .onOldPasswordTextChanged(let text):
                viewModel.oldPassword = text
            case .onNewPasswordTextChanged(let text):
                viewModel.newPassword = text
            case .onRepeatNewPasswordTextChanged(let text):
                viewModel.repeatNewPassword = text
            case .onUpdateTap:
                Task.detached {
                    await self.updatePassword()
                }
            }
        }
    }
}

// MARK: - Private

extension UpdatePasswordFlow {
    private func updatePassword() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.value.errorHaptic()
        }
        await presenter.value.presentLoading()
        do {
            try await profileEditing.updatePassword(old: state.oldPassword, new: state.newPassword)
            await saveCredentials.save(email: profile.email, password: state.newPassword)
            await presenter.value.successHaptic()
            await presenter.value.presentSuccess()
            await handle(event: .successfullySet)
        } catch {
            switch error {
            case .validationError:
                await presenter.value.presentHint(message: "change_password_format_error".localized)
            case .incorrectOldPassword:
                await presenter.value.presentHint(message: "change_password_old_wrong".localized)
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
    }
}
