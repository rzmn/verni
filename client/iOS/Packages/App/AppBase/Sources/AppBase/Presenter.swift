import Foundation

public protocol Presenter {
    var router: AppRouter { get }

    @MainActor func presentLoading()
    @MainActor func presentNoConnection()
    @MainActor func presentInternalError(_ error: Error)
}

public extension Presenter {
    @MainActor func presentLoading() {
        router.showHud(graceTime: 0.5)
    }

    @MainActor func presentNoConnection() {
        router.hudFailure(description: "no_connection_hint".localized)
    }

    @MainActor func presentInternalError(_ error: Error) {
        router.hudFailure(description: "\(error)")
    }
}
