import AppBase
import Combine
import Domain
import DI

public actor UpdatePasswordFlow {
    @MainActor var subject: Published<UpdatePasswordState>.Publisher {
        viewModel.$state
    }

    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private lazy var presenter = UpdatePasswordFlowPresenter(router: router, flow: self)

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
    public enum TerminationEvent {
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
        await self.presenter.presentPasswordEditing { [weak self] in
            guard let self else { return }
            await handle(event: .canceled)
        }
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension UpdatePasswordFlow {
    @MainActor func update(oldPassword: String) {
        viewModel.oldPassword = oldPassword
    }

    @MainActor func update(newPassword: String) {
        viewModel.newPassword = newPassword
    }

    @MainActor func update(repeatNewPassword: String) {
        viewModel.repeatNewPassword = repeatNewPassword
    }

    @MainActor func updatePassword() {
        Task.detached {
            await self.doUpdatePassword()
        }
    }
}

// MARK: - Private

extension UpdatePasswordFlow {
    private func doUpdatePassword() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.errorHaptic()
        }
        switch await profileEditing.updatePassword(old: state.oldPassword, new: state.newPassword) {
        case .success:
            await saveCredentials.save(email: profile.email, password: state.newPassword)
            await handle(event: .successfullySet)
        case .failure(let error):
            switch error {
            case .validationError:
                await presenter.presentHint(message: "change_password_format_error".localized)
            case .incorrectOldPassword:
                await presenter.presentHint(message: "change_password_old_wrong".localized)
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }
}
