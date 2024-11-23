import SwiftUI
import DI
import AppBase
internal import AuthWelcomeScreen
internal import DesignSystem

public struct AppView: View {
    @ObservedObject private var store: Store<AppState, AppAction>
    @State var showingDebugMenu = true

    init(store: Store<AppState, AppAction>) {
        self.store = store
    }

    public var body: some View {
        content
            .onShake {
                if !showingDebugMenu {
                    withAnimation {
                        showingDebugMenu = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingDebugMenu, content: {
                if case .launched(let state) = store.state, case .anonymous(let state) = state {
                    state.session.debugMenuScreen.instantiate { event in
                        switch event {
                        case .dismiss:
                            withAnimation {
                                showingDebugMenu = false
                            }
                        }
                    }
                } else {
                    Text("debug menu for authenticated")
                }
            })
            .environment(ColorPalette.light)
            .environment(PaddingsPalette.default)
    }
    
    @ViewBuilder private var content: some View {
        switch store.state {
        case .launching:
            Text("launching...")
                .onAppear {
                    store.dispatch(.launch)
                }
        case .launched(let state):
            switch state {
            case .authenticated:
                Text("launched...")
            case .anonymous(let state):
                state.session.authWelcomeScreen.instantiate { event in
                    // not implemented
                }
            }
        }
    }
}
