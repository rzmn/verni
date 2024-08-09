import Foundation

public protocol Presenter {
    var router: AppRouter { get }

    @MainActor func presentLoading()
    @MainActor func dismissLoading()
    @MainActor func presentSuccess()
    @MainActor func presentNotAuthorized()
    @MainActor func presentNoConnection()
    @MainActor func presentInternalError(_ error: Error)
}

public extension Presenter {
    @MainActor func presentSuccess() {
        router.hudSuccess()
    }

    @MainActor func dismissLoading() {
        router.hideHud()
    }

    @MainActor func presentHint(message: String) {
        router.hudFailure(description: message)
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
}
