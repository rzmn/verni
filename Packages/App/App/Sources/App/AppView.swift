import SwiftUI
import DI
import AppBase
internal import DesignSystem
internal import DebugMenuScreen

public struct AppView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject private var store: Store<AppState, AppAction>
    @State private var showingDebugMenu = false

    init(store: Store<AppState, AppAction>) {
        self.store = store
    }

    public var body: some View {
        contentWithDebugMenu
            .environment(ColorPalette(scheme: colorScheme))
            .environment(PaddingsPalette.default)
    }
    
    @ViewBuilder private var contentWithDebugMenu: some View {
        content
            .onShake {
                withAnimation {
                    showingDebugMenu = true
                }
            }
            .fullScreenCover(isPresented: $showingDebugMenu) {
                DefaultDebugMenuFactory()
                    .create()
                    .instantiate { event in
                        switch event {
                        case .dismiss:
                            withAnimation {
                                showingDebugMenu = false
                            }
                        }
                    }()
            }
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
                AuthenticatedNavigation(store: store)
            case .anonymous:
                AnonymousNavigation(store: store)
            }
        }
    }
}
