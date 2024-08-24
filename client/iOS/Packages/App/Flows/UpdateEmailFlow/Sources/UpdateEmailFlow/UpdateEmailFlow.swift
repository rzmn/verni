import AppBase
import Combine
import Domain
import UIKit
import DI

public actor UpdateEmailFlow {
    @MainActor var subject: Published<UpdateEmailState>.Publisher {
        viewModel.$state
    }

    private let viewModel: UpdateEmailViewModel

    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private let emailConfirmationUseCase: EmailConfirmationUseCase
    private lazy var presenter = UpdateEmailFlowPresenter(router: router, flow: self)

    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter, profile: Profile) async {
        self.router = router
        self.profileEditing = di.profileEditingUseCase()
        self.emailConfirmationUseCase = di.emailConfirmationUseCase()
        self.viewModel = await UpdateEmailViewModel(
            profile: profile,
            confirmationCodeLength: emailConfirmationUseCase.confirmationCodeLength
        )
    }
}

extension UpdateEmailFlow: Flow {
    public enum TerminationEvent: Error {
        case canceledManually
    }

    public func perform() async -> Result<Profile, TerminationEvent> {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached { @MainActor in
                await self.presenter.presentEmailEditing { [weak self] in
                    guard let self else { return }
                    await handle(result: .failure(.canceledManually))
                }
            }
        }
    }

    private func handle(result: Result<Profile, TerminationEvent>) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: result)
    }

    @MainActor
    func confirm() {
        guard viewModel.state.canConfirm else {
            Task.detached { @MainActor in
                await self.presenter.errorHaptic()
            }
            return
        }
        viewModel.confirmationInProgress = true
        Task.detached {
            await self.doConfirm()
        }
    }

    @MainActor
    func update(code: String) {
        viewModel.confirmationCode = code
    }

    @MainActor
    func resendCode() {
        guard viewModel.state.canResendCode else {
            Task.detached { @MainActor in
                await self.presenter.errorHaptic()
            }
            return
        }
        viewModel.resendInProgress = true
        Task.detached {
            await self.doResendCode()
        }
    }
}

extension UpdateEmailFlow {
    func doResendCode() async {
        let result = await emailConfirmationUseCase.sendConfirmationCode()
        switch result {
        case .success:
            await presenter.codeSent()
            await viewModel.startCountdownTimer()
        case .failure(let error):
            switch error {
            case .notDelivered:
                await presenter.codeNotDelivered()
            case .alreadyConfirmed:
                await presenter.emailAlreadyConfirmed()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
        Task { @MainActor [unowned viewModel] in
            viewModel.resendInProgress = false
        }
    }

    private func doConfirm() async {
        guard case .uncorfirmed(let uncorfirmed) = await viewModel.state.confirmation else {
            return assertionFailure()
        }
        await self.presenter.submitHaptic()
        let result = await emailConfirmationUseCase.confirm(
            code: uncorfirmed.currentCode.trimmingCharacters(in: CharacterSet.whitespaces)
        )
        switch result {
        case .success:
            await viewModel.cancelCountdownTimer()
            Task { @MainActor [unowned viewModel] in
                viewModel.confirmed = true
            }
            await presenter.successHaptic()
            await presenter.presentSuccess()
        case .failure(let error):
            switch error {
            case .codeIsWrong:
                Task { @MainActor [unowned viewModel] in
                    viewModel.confirmationCode = ""
                }
                await presenter.codeIsWrong()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
        Task { @MainActor [unowned viewModel] in
            viewModel.confirmationInProgress = false
        }
    }
}
