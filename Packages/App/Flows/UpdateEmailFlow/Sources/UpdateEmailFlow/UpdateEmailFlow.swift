import AppBase
import Combine
import Domain
import UIKit
import DI

public actor UpdateEmailFlow {
    private var _presenter: UpdateEmailPresenter?
    @MainActor private func presenter() async -> UpdateEmailPresenter {
        guard let presenter = await _presenter else {
            let presenter = UpdateEmailPresenter(router: router, actions: await makeActions())
            await mutate { s in
                s._presenter = presenter
            }
            return presenter
        }
        return presenter
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
                await self.presenter().presentEmailEditing { [weak self] in
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
    @MainActor private func makeActions() async -> UpdateEmailViewActions {
        UpdateEmailViewActions(state: viewModel.$state) { [weak self] actions in
            guard let self else { return }
            switch actions {
            case .onConfirmTap:
                guard viewModel.state.canConfirm else {
                    Task.detached {
                        await self.presenter().errorHaptic()
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
                        await self.presenter().errorHaptic()
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
            await presenter().codeSent()
            await viewModel.startCountdownTimer()
        } catch {
            switch error {
            case .notDelivered:
                await presenter().codeNotDelivered()
            case .alreadyConfirmed:
                await presenter().emailAlreadyConfirmed()
            case .other(let error):
                await presenter().presentGeneralError(error)
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
        await self.presenter().submitHaptic()
        do {
            try await emailConfirmationUseCase.confirm(
                code: uncorfirmed.currentCode.trimmingCharacters(in: CharacterSet.whitespaces)
            )
            await viewModel.cancelCountdownTimer()
            Task { @MainActor [unowned viewModel] in
                viewModel.confirmed = true
            }
            await presenter().successHaptic()
            await presenter().presentSuccess()
        } catch {
            switch error {
            case .codeIsWrong:
                Task { @MainActor [unowned viewModel] in
                    viewModel.confirmationCode = ""
                }
                await presenter().codeIsWrong()
            case .other(let error):
                await presenter().presentGeneralError(error)
            }
        }
        Task { @MainActor [unowned viewModel] in
            viewModel.confirmationInProgress = false
        }
    }
}
