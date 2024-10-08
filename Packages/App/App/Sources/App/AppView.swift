import SwiftUI
import DI
import AppBase
internal import SignInScreen

public struct AppView: View {
    @ObservedObject private var store: Store<AppState, AppAction>

    init(store: Store<AppState, AppAction>) {
        self.store = store
    }

    public var body: some View {
        switch store.state {
        case .launching:
            Text("launching...")
                .onAppear {
                    store.dispatch(.launch)
                }
        case .launched:
            Text("launched...")
        }
    }
}
