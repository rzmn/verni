import SwiftUI
import AppBase
import DesignSystem
internal import Convenience

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

    public init(store: Store<AppState, AppAction>) {
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
            .onOpenURL { url in
                guard let appUrl = AppUrl(url: url) else {
                    return
                }
                switch appUrl {
                case .users(let url):
                    switch url {
                    case .show(let user):
                        store.dispatch(.onUserPreview(user))
                    }
                }
            }
    }

    @ViewBuilder private var contentWithDebugMenu: some View {
        contentWithSplash
            .onShake {
                withAnimation {
                    showingDebugMenu = true
                }
            }
            .fullScreenCover(isPresented: $showingDebugMenu) {
                store.state.shared.debug.instantiate { event in
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
            store.state.shared.splash.instantiate()(
                ModalTransition(
                    progress: $fromSplashTransitionProgress,
                    sourceOffset: $splashDestinationOffset,
                    destinationOffset: $authWelcomeSourceOffset
                )
            )
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
