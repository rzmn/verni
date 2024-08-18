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
    private let profileRepository: UsersRepository
    private let profile: Profile

    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter, profile: Profile) async {
        self.router = router
        self.profile = profile
        self.saveCredentials = di.appCommon().saveCredentials()
        self.profileEditing = di.profileEditingUseCase()
        self.profileRepository = di.usersRepository()
        viewModel = await UpdatePasswordViewModel(
            passwordValidation: di.appCommon().localPasswordValidationUseCase()
        )
    }
}

extension UpdatePasswordFlow: Flow {
    public enum TerminationEvent: Error {
        case canceledManually
    }

    public func perform() async -> Result<Profile, TerminationEvent> {
        await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached { @MainActor in
                await self.presenter.presentPasswordEditing { [weak self] in
                    guard let self else { return }
                    await handle(result: .failure(.canceledManually))
                }
            }
        }
    }

    func updatePassword() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.errorHaptic()
        }
        switch await profileEditing.updatePassword(old: state.oldPassword, new: state.newPassword) {
        case .success:
            await saveCredentials.save(email: profile.email, password: state.newPassword)
            switch await profileRepository.getHostInfo() {
            case .success(let profile):
                await presenter.successHaptic()
                await presenter.presentSuccess()
                await handle(result: .success(profile))
            case .failure(let error):
                await presenter.presentGeneralError(error)
            }
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

    @MainActor
    func update(oldPassword: String) {
        viewModel.oldPassword = oldPassword
    }

    @MainActor
    func update(newPassword: String) {
        viewModel.newPassword = newPassword
    }

    @MainActor
    func update(repeatNewPassword: String) {
        viewModel.repeatNewPassword = repeatNewPassword
    }

    private func handle(result: Result<Profile, TerminationEvent>) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: result)
    }
}
