import SwiftUI
import DI
import AppBase
internal import Base
internal import DesignSystem
internal import DebugMenuScreen
internal import SplashScreen

public struct AppView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject private var store: Store<AppState, AppAction>
    @State private var showingDebugMenu = false

    @State private var authWelcomeSourceOffset: CGFloat?
    @State private var splashDestinationOffset: CGFloat?

    @State private var fromSplashTransitionProgress: CGFloat = 0
    @State private var toContentTransitionProgress: CGFloat = 0

    @State private var contentOpacity: CGFloat = 0

    @State private var splashIsLocked = false

    init(store: Store<AppState, AppAction>) {
        self.store = store
    }

    public var body: some View {
        contentWithDebugMenu
            .dynamicIslandContent {
                Image.logoHorizontalSmall
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(ColorPalette(scheme: colorScheme).icon.primary.default)
            }
            .environment(ColorPalette(scheme: colorScheme))
            .environment(PaddingsPalette.default)
    }

    @ViewBuilder private var contentWithDebugMenu: some View {
        contentWithSplash
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

    @ViewBuilder private var contentWithSplash: some View {
        ZStack {
            DefaultSplashFactory().instantiate()(ModalTransition(progress: $fromSplashTransitionProgress, sourceOffset: $splashDestinationOffset, destinationOffset: $authWelcomeSourceOffset))
            .onAppear {
                store.dispatch(.launch)
            }
            content
        }
    }

    @ViewBuilder private var content: some View {
        switch store.state {
        case .launching:
            EmptyView()
        case .launched(let state):
            switch state {
            case .authenticated:
                AuthenticatedScreensCoordinator(store: store, appearTransitionProgress: $toContentTransitionProgress)
                    .opacity(contentOpacity)
                    .onAppear {
                        withAnimation(.default) {
                            fromSplashTransitionProgress = 1
                        } completion: {
                            contentOpacity = 1
                            withAnimation(.default) {
                                toContentTransitionProgress = 1
                            } completion: {
                                splashIsLocked = true
                            }
                        }
                    }
            case .anonymous:
                AnonymousScreensCoordinator(store: store, fromSplashTransitionProgress: $toContentTransitionProgress)
                    .opacity(contentOpacity)
                    .onAppear {
                        withAnimation(.default) {
                            fromSplashTransitionProgress = 1
                        } completion: {
                            contentOpacity = 1
                            withAnimation(.default) {
                                toContentTransitionProgress = 1
                            } completion: {
                                splashIsLocked = true
                            }
                        }
                    }
            }
        }
    }
}
