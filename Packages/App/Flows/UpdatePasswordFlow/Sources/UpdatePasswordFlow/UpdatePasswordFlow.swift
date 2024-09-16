import AppBase
import Combine
import Domain
import DI

public actor UpdatePasswordFlow {
    private var _presenter: UpdatePasswordPresenter?
    @MainActor private func presenter() async -> UpdatePasswordPresenter {
        guard let presenter = await _presenter else {
            let presenter = UpdatePasswordPresenter(router: router, actions: await makeActions())
            await mutate { s in
                s._presenter = presenter
            }
            return presenter
        }
        return presenter
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
        await presenter().presentPasswordEditing { [weak self] in
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
            await presenter().cancelPasswordEditing()
        }
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension UpdatePasswordFlow {
    @MainActor private func makeActions() async -> UpdatePasswordViewActions {
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
            return await presenter().errorHaptic()
        }
        await presenter().presentLoading()
        do {
            try await profileEditing.updatePassword(old: state.oldPassword, new: state.newPassword)
            await saveCredentials.save(email: profile.email, password: state.newPassword)
            await presenter().successHaptic()
            await presenter().presentSuccess()
            await handle(event: .successfullySet)
        } catch {
            switch error {
            case .validationError:
                await presenter().presentHint(message: "change_password_format_error".localized)
            case .incorrectOldPassword:
                await presenter().presentHint(message: "change_password_old_wrong".localized)
            case .other(let error):
                await presenter().presentGeneralError(error)
            }
        }
    }
}
