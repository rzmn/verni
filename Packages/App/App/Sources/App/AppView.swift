import SwiftUI
import DI
import AppBase
internal import AuthWelcomeScreen
internal import DesignSystem

public struct AppView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject private var store: Store<AppState, AppAction>
    @State var showingDebugMenu = false
    @State var showingLoginScreen = false

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
            .fullScreenCover(isPresented: $showingLoginScreen, content: {
                if case .launched(let state) = store.state, case .anonymous(let state) = state {
                    state.session.logInScreen.instantiate { event in
                        switch event {
                        case .dismiss:
                            withAnimation {
                                showingLoginScreen = false
                            }
                        default:
                            break
                        }
                    }
                    .fullScreenCover(
                        isPresented: Binding(
                            get: {
                                if !showingLoginScreen {
                                    return false
                                }
                                return showingDebugMenu
                            }, set: { newValue in
                                showingDebugMenu = newValue
                            }
                        ),
                        content: {
                            debugMenu
                        }
                    )
                } else {
                    Text("debug menu for authenticated")
                }
            })
            .fullScreenCover(
                isPresented: Binding(
                    get: {
                        if showingLoginScreen {
                            return false
                        }
                        return showingDebugMenu
                    }, set: { newValue in
                        showingDebugMenu = newValue
                    }
                ),
                content: {
                    debugMenu
                }
            )
            .environment(ColorPalette(scheme: colorScheme))
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
                    switch event {
                    case .logIn:
                        showingLoginScreen = true
                    case .signUp:
                        break
                    }
                }
            }
        }
    }
    
    @ViewBuilder private var debugMenu: some View {
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
    }
}
