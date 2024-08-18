import Combine
import Foundation
import Domain

@MainActor
public class UpdateEmailViewModel {
    @Published var state: UpdateEmailState

    @Published var confirmationCode: String
    @Published var resendCountdownTimer: Int?
    @Published var confirmed: Bool
    @Published var confirmationInProgress: Bool
    @Published var resendInProgress: Bool

    private var countdownTimer: AnyCancellable?
    private let confirmationCodeLength: Int

    init(profile: Profile, confirmationCodeLength: Int) {
        let initial = UpdateEmailState(
            email: profile.email,
            confirmation: profile.isEmailVerified ? .confirmed : .uncorfirmed(.initial),
            confirmationCodeLength: confirmationCodeLength
        )
        state = initial
        confirmationCode = ""
        resendCountdownTimer = nil
        confirmed = profile.isEmailVerified
        confirmationInProgress = false
        resendInProgress = false

        self.confirmationCodeLength = confirmationCodeLength
        setupStateBuilder()
    }

    private func setupStateBuilder() {
        Publishers.CombineLatest3(
            Publishers.CombineLatest(Just(state.email), $confirmed),
            Publishers.CombineLatest3($resendCountdownTimer, $confirmationCode, Just(confirmationCodeLength)),
            Publishers.CombineLatest($resendInProgress, $confirmationInProgress)
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
        .removeDuplicates()
        .assign(to: &$state)
    }
}

extension UpdateEmailViewModel {
    func cancelCountdownTimer() {
        resendCountdownTimer = nil
        countdownTimer = nil
    }

    func startCountdownTimer() {
        resendCountdownTimer = 60
        countdownTimer = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard let resendCountdownTimer else {
                    return
                }
                if resendCountdownTimer <= 1 {
                    Task.detached {
                        await self.cancelCountdownTimer()
                    }
                } else {
                    self.resendCountdownTimer = resendCountdownTimer - 1
                }
            }
    }
}
