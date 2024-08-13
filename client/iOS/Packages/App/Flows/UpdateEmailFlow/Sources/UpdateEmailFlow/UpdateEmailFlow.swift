import AppBase
import Combine
import Domain
import UIKit
import DI

public actor UpdateEmailFlow {
    @MainActor var subject: CurrentValueSubject<UpdateEmailState, Never> {
        viewModel.subject
    }
    private let viewModel: UpdateEmailViewModel

    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private let emailConfirmationUseCase: EmailConfirmationUseCase
    private lazy var presenter = UpdateEmailFlowPresenter(router: router, flow: self)

    private var flowHandlers = [AnyHashable: AnyFlowEventHandler<FlowEvent>]()
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
        await viewModel.setup()
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
        guard subject.value.canConfirm else {
            Task.detached { @MainActor in
                await self.presenter.errorHaptic()
            }
            return
        }
        viewModel.confirmInProgress(true)
        Task.detached {
            await self.doConfirm()
        }
    }

    @MainActor
    func update(code: String) {
        viewModel.codeUpdated(code)
    }

    @MainActor
    func resendCode() {
        guard subject.value.canResendCode else {
            Task.detached { @MainActor in
                await self.presenter.errorHaptic()
            }
            return
        }
        viewModel.resendInProgress(true)
        Task.detached {
            await self.doResendCode()
        }
    }
}

extension UpdateEmailFlow: FlowEvents {
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
        await viewModel.resendInProgress(false)
    }

    private func doConfirm() async {
        guard case .uncorfirmed(let uncorfirmed) = viewModel.subject.value.confirmation else {
            return assertionFailure()
        }
        await self.presenter.submitHaptic()
        let result = await emailConfirmationUseCase.confirm(
            code: uncorfirmed.currentCode.trimmingCharacters(in: CharacterSet.whitespaces)
        )
        switch result {
        case .success:
            await viewModel.cancelCountdownTimer()
            await viewModel.codeConfirmed()
            await presenter.successHaptic()
            await presenter.presentSuccess()
        case .failure(let error):
            switch error {
            case .codeIsWrong:
                await viewModel.codeUpdated("")
                await presenter.codeIsWrong()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
        await viewModel.confirmInProgress(false)
    }
}
