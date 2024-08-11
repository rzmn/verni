import AppBase
import Combine
import Domain
import UIKit
import DI

actor UpdateEmailFlow {
    let subject: CurrentValueSubject<UpdateEmailState, Never>

    private let confirmationCodeSubject = CurrentValueSubject<String, Never>("")
    private let resendCountdownTimerSubject = CurrentValueSubject<Int?, Never>(nil)
    private let confirmedSubject: CurrentValueSubject<Bool, Never>

    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private let emailConfirmationUseCase: EmailConfirmationUseCase
    private lazy var presenter = UpdateEmailFlowPresenter(router: router, flow: self)
    private var subscriptions = Set<AnyCancellable>()
    private var countdownTimer: AnyCancellable?

    private var flowContinuation: Continuation?

    init(di: ActiveSessionDIContainer, router: AppRouter, profile: Profile) {
        self.router = router
        self.profileEditing = di.profileEditingUseCase()
        self.emailConfirmationUseCase = di.emailConfirmationUseCase()
        confirmedSubject = CurrentValueSubject(profile.isEmailVerified)
        subject = CurrentValueSubject(
            UpdateEmailState(
                email: profile.email,
                confirmation: profile.isEmailVerified ? .confirmed : .uncorfirmed(currentCode: "", resendCountdownHint: nil)
            )
        )
    }
}

extension UpdateEmailFlow: Flow {
    enum TerminationEvent: Error {
        case canceledManually
    }

    func perform(willFinish: ((Result<Profile, TerminationEvent>) async -> Void)?) async -> Result<Profile, TerminationEvent> {
        let email = Just(subject.value.email)

        Publishers.CombineLatest4(confirmedSubject, confirmationCodeSubject, resendCountdownTimerSubject, email)
            .map { value in
                let (confirmed, code, resentCountdown, email) = value
                let resentCountdownHint = resentCountdown.flatMap { "\($0)" }
                return UpdateEmailState(
                    email: email,
                    confirmation: confirmed ? .confirmed : .uncorfirmed(currentCode: code, resendCountdownHint: resentCountdownHint)
                )
            }
            .sink(receiveValue: subject.send)
            .store(in: &subscriptions)

        return await withCheckedContinuation { continuation in
            self.flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
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
        await flowContinuation.willFinishHandler?(result)
        flowContinuation.continuation.resume(returning: result)
    }

    private func cancelCountdownTimer() {
        resendCountdownTimerSubject.send(nil)
        countdownTimer = nil
    }

    private func startCountdownTimer() {
        resendCountdownTimerSubject.send(60)
        countdownTimer = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard let countdown = resendCountdownTimerSubject.value else {
                    return
                }
                if countdown <= 1 {
                    Task.detached {
                        await self.cancelCountdownTimer()
                    }
                } else {
                    resendCountdownTimerSubject.send(countdown - 1)
                }
            }
    }

    func confirm() async {
        guard subject.value.canConfirm else {
            return await presenter.errorHaptic()
        }
        switch await emailConfirmationUseCase.confirm(code: confirmationCodeSubject.value.trimmingCharacters(in: CharacterSet.whitespaces)) {
        case .success:
            cancelCountdownTimer()
            confirmedSubject.send(true)
            await presenter.successHaptic()
            await presenter.presentSuccess()
        case .failure(let error):
            switch error {
            case .codeIsWrong:
                await presenter.codeIsWrong()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    @MainActor
    func update(code: String) {
        confirmationCodeSubject.send(code)
    }

    func resendCode() async {
        switch await emailConfirmationUseCase.sendConfirmationCode() {
        case .success:
            await presenter.codeSent()
            startCountdownTimer()
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
    }
}
