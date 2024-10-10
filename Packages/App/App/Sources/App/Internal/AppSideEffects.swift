import AppBase
import DI

@MainActor final class AppSideEffects: Sendable {
    private unowned let store: Store<AppState, AppAction>
    private let di: AnonymousDomainLayerSession

    init(store: Store<AppState, AppAction>, di: AnonymousDomainLayerSession) {
        self.store = store
        self.di = di
    }
}

extension AppSideEffects: ActionHandler {
    var id: String {
        "\(Self.self)"
    }

    func handle(_ action: AppAction) {
        switch action {
        case .launch:
            launch()
        case .launched:
            launched()
        case .onAuthorized:
            onAuthorized()
        }
    }

    private func launch() {
        Task {
            let session = await AnonymousPresentationLayerSession(di: di)
            store.dispatch(.launched(.anonymous(session)))
        }
    }

    private func launched() {
        // stub
    }

    private func onAuthorized() {
        // stub
    }
}
