import Combine
import Foundation
import Domain

@MainActor
public class UpdateEmailViewModel {
    let subject: CurrentValueSubject<UpdateEmailState, Never>

    private let confirmationCodeSubject = CurrentValueSubject<String, Never>("")
    private let resendCountdownTimerSubject = CurrentValueSubject<Int?, Never>(nil)
    private let confirmedSubject: CurrentValueSubject<Bool, Never>
    private let confirmationInProgressSubject = CurrentValueSubject<Bool, Never>(false)
    private let resendInProgressSubject = CurrentValueSubject<Bool, Never>(false)
    private var countdownTimer: AnyCancellable?
    private let confirmationCodeLength: Int

    private var subscriptions = Set<AnyCancellable>()

    init(profile: Profile, confirmationCodeLength: Int) {
        self.confirmedSubject = CurrentValueSubject(profile.isEmailVerified)
        self.confirmationCodeLength = confirmationCodeLength
        self.subject = CurrentValueSubject(
            UpdateEmailState(
                email: profile.email,
                confirmation: profile.isEmailVerified ? .confirmed : .uncorfirmed(.initial),
                confirmationCodeLength: confirmationCodeLength
            )
        )
    }

    func setup() {
        Publishers.CombineLatest3(
            Publishers.CombineLatest(Just(subject.value.email), confirmedSubject),
            Publishers.CombineLatest3(resendCountdownTimerSubject, confirmationCodeSubject, Just(confirmationCodeLength)),
            Publishers.CombineLatest(resendInProgressSubject, confirmationInProgressSubject)
        ).map { value in
            let (email, isConfirmed) = value.0
            let (countdown, code, codeLenght) = value.1
            let (resendInProgress, confirmationInProgress) = value.2
            return UpdateEmailState(
                email: email,
                confirmation: isConfirmed ? .confirmed : .uncorfirmed(
                    UpdateEmailState.Confirmation.Unconfirmed(
                        currentCode: code,
                        resendCountdownHint: countdown.flatMap { "\($0)" },
                        resendInProgress: resendInProgress,
                        confirmationInProgress: confirmationInProgress
                    )
                ),
                confirmationCodeLength: codeLenght
            )
        }
        .sink(receiveValue: subject.send)
        .store(in: &subscriptions)
    }

    func resendInProgress(_ inProgress: Bool) {
        resendInProgressSubject.send(inProgress)
    }

    func confirmInProgress(_ inProgress: Bool) {
        confirmationInProgressSubject.send(inProgress)
    }

    func codeConfirmed() {
        confirmedSubject.send(true)
    }

    func codeUpdated(_ code: String) {
        confirmationCodeSubject.send(code)
    }
}

extension UpdateEmailViewModel {
    func cancelCountdownTimer() {
        resendCountdownTimerSubject.send(nil)
        countdownTimer = nil
    }

    func startCountdownTimer() {
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
}
