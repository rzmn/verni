import AppBase
import Combine
import Domain
import UIKit
import DI
import AsyncExtensions

public actor UpdateEmailFlow {
    private lazy var presenter = AsyncLazyObject {
        UpdateEmailPresenter(
            router: self.router,
            actions: await MainActor.run {
                self.makeActions()
            }
        )
    }
    private let viewModel: UpdateEmailViewModel
    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private let emailConfirmationUseCase: EmailConfirmationUseCase

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

// MARK: - Flow

extension UpdateEmailFlow: Flow {
    public enum TerminationEvent: Error {
        case canceledManually
    }

    public func perform() async -> Result<Profile, TerminationEvent> {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task {
                await self.presenter.value.presentEmailEditing { [weak self] in
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
}

// MARK: - User Actions

extension UpdateEmailFlow {
    @MainActor private func makeActions() -> UpdateEmailViewActions {
        UpdateEmailViewActions(state: viewModel.$state) { [weak self] actions in
            guard let self else { return }
            switch actions {
            case .onConfirmTap:
                guard viewModel.state.canConfirm else {
                    Task.detached {
                        await self.presenter.value.errorHaptic()
                    }
                    return
                }
                viewModel.confirmationInProgress = true
                Task.detached {
                    await self.confirm()
                }
            case .onConfirmationCodeTextChanged(let text):
                viewModel.confirmationCode = text
            case .onResendTap:
                guard viewModel.state.canResendCode else {
                    Task.detached {
                        await self.presenter.value.errorHaptic()
                    }
                    return
                }
                viewModel.resendInProgress = true
                Task.detached {
                    await self.resendCode()
                }
            }
        }
    }
}

// MARK: - Private

extension UpdateEmailFlow {
    func resendCode() async {
        do {
            try await emailConfirmationUseCase.sendConfirmationCode()
            await presenter.value.codeSent()
            await viewModel.startCountdownTimer()
        } catch {
            switch error {
            case .notDelivered:
                await presenter.value.codeNotDelivered()
            case .alreadyConfirmed:
                await presenter.value.emailAlreadyConfirmed()
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
        Task { @MainActor [unowned viewModel] in
            viewModel.resendInProgress = false
        }
    }

    private func confirm() async {
        guard case .uncorfirmed(let uncorfirmed) = await viewModel.state.confirmation else {
            return assertionFailure()
        }
        await self.presenter.value.submitHaptic()
        do {
            try await emailConfirmationUseCase.confirm(
                code: uncorfirmed.currentCode.trimmingCharacters(in: CharacterSet.whitespaces)
            )
            await viewModel.cancelCountdownTimer()
            Task { @MainActor [unowned viewModel] in
                viewModel.confirmed = true
            }
            await presenter.value.successHaptic()
            await presenter.value.presentSuccess()
        } catch {
            switch error {
            case .codeIsWrong:
                Task { @MainActor [unowned viewModel] in
                    viewModel.confirmationCode = ""
                }
                await presenter.value.codeIsWrong()
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
        Task { @MainActor [unowned viewModel] in
            viewModel.confirmationInProgress = false
        }
    }
}
