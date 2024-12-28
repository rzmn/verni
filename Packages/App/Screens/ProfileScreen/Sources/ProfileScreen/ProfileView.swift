import SwiftUI
import Domain
import AppBase
internal import DesignSystem
internal import Base

public struct ProfileView: View {
    @ObservedObject var store: Store<ProfileState, ProfileAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    @Binding private var tabTransitionProgress: CGFloat

    init(store: Store<ProfileState, ProfileAction>, transitions: ProfileTransitions) {
        self.store = store
        _tabTransitionProgress = transitions.tab.progress
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .background(colors.background.secondary.default)
                .opacity(tabTransitionOpacity)
                .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            ProfileCardView(store: store)
                .padding(2)
                .background(
                    colors.background.secondary.default
                        .overlay(
                            colors.background.primary.default
                                .padding(.top, 22)
                        )
                        .overlay(
                            colors.background.primary.default
                                .clipShape(.rect(cornerRadius: 22))
                        )
                )
                .clipped()
                .opacity(tabTransitionOpacity)
                .animation(.default.speed(5), value: tabTransitionOpacity)
                .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            ProfileSettingsList(store: store)
                .opacity(tabTransitionOpacity)
                .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
                .padding(.horizontal, 2)
            Spacer()

        }
        .background(colors.background.primary.default.opacity(tabTransitionOpacity))
        .onAppear {
            store.dispatch(.onRefreshProfile)
        }
    }

    private var navigationBar: some View {
        NavigationBar(
            config: NavigationBar.Config(
                leftItem: NavigationBar.Item(
                    config: NavigationBar.ItemConfig(
                        style: .primary,
                        icon: .bellBorder
                    ),
                    action: {
                        store.dispatch(.onNotificationsTap)
                    }
                ),
                rightItem: NavigationBar.Item(
                    config: NavigationBar.ItemConfig(
                        style: .primary,
                        icon: .logout
                    ),
                    action: {
                        store.dispatch(.onLogoutTap)
                    }
                ),
                title: .profileTitle,
                style: .primary
            )
        )
    }
}

// MARK: - Transitions

extension ProfileView {
    private var tabTransitionOpacity: CGFloat {
        1 - abs(tabTransitionProgress)
    }

    private var tabTransitionOffset: CGFloat {
        28 * tabTransitionProgress
    }
}

#if DEBUG

private struct ProfilePreview: View {
    @State var tabTransition: CGFloat = 0

    var body: some View {
        ZStack {
            ProfileView(
                store: Store(
                    state: modify(ProfileModel.initialState) {
                        $0.profile = .loaded(
                            Profile(
                                user: User(
                                    id: "",
                                    status: .currentUser,
                                    displayName: "berchikk",
                                    avatar: Avatar(id: "123")
                                ),
                                email: "email@verni.co",
                                isEmailVerified: false
                            )
                        )
                        $0.avatarCardFlipCount = 0
                    },
                    reducer: ProfileModel.reducer
                ),
                transitions: ProfileTransitions(
                    tab: TabTransition(
                        progress: $tabTransition
                    )
                )
            )
            .environment(ColorPalette.light)
            VStack {
                Slider(value: $tabTransition, in: -1...1)
            }
        }
    }
}

#Preview {
    ProfilePreview()
        .preview(packageClass: ProfileModel.self)
}

#endif
