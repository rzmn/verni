import UIKit
import Domain

public protocol Presenter: HapticManager {
    var router: AppRouter { get }

    @MainActor func presentLoading()
    @MainActor func dismissLoading()
    @MainActor func presentSuccess()

    @MainActor func presentNotAuthorized()
    @MainActor func presentNoConnection()
    @MainActor func presentNoSuchUser()
    @MainActor func presentInternalError(_ error: Error)

    @MainActor func presentGeneralError(_ error: GeneralError)
}

public protocol HapticManager {
    @MainActor func errorHaptic()
    @MainActor func successHaptic()
    @MainActor func warningHaptic()
    @MainActor func submitHaptic()
}

public extension HapticManager {
    @MainActor func errorHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    @MainActor func successHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor func submitHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.66)
    }

    @MainActor func warningHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

public extension Presenter {
    @MainActor func presentSuccess() {
        router.hudSuccess()
    }

    @MainActor func dismissLoading() {
        router.hideHud()
    }

    @MainActor func presentLoading() {
        router.showHud(graceTime: 0.5)
    }

    @MainActor func presentNoConnection() {
        router.hudFailure(description: "no_connection_hint".localized)
    }

    @MainActor func presentInternalError(_ error: Error) {
        router.hudFailure(description: "\(error)")
    }

    @MainActor func presentNotAuthorized() {
        router.hudFailure(description: "alert_title_unauthorized".localized)
    }

    @MainActor func presentNoSuchUser() {
        router.hudFailure(description: "alert_action_no_such_user".localized)
    }

    @MainActor func presentGeneralError(_ error: GeneralError) {
        switch error {
        case .noConnection:
            presentNoConnection()
        case .notAuthorized:
            presentNotAuthorized()
        case .other(let error):
            presentInternalError(error)
        }
    }
}
