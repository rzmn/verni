import SwiftUI
import AppBase
import Domain
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
            .background(colors.background.secondary.default)
            .opacity(tabTransitionOpacity)
            .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            FlipView(
                frontView: avatarCard.padding(.all, 2),
                backView: qrCodeCard.padding(.all, 2),
                flipsCount: Binding(
                    get: {
                        store.state.avatarCardFlipCount
                    },
                    set: { _ in
                        store.dispatch(.onFlipAvatarTap)
                    }
                )
            )
            .aspectRatio(cardAspectRatio, contentMode: .fit)
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
            .animation(.default.speed(10), value: tabTransitionOpacity)
            .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            menuOptions
                .padding(.horizontal, 2)

        }
        .overlay {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        let side = qrCodeSide(geometry: geometry)
                        if side > 0 {
                            store.dispatch(.onRequestQrImage(size: side * Int(UIScreen.main.scale)))
                        }
                    }
            }
        }
        .onAppear {
            store.dispatch(.onRefreshProfile)
        }
    }
    
    @ViewBuilder private var avatarCard: some View {
        AvatarView(
            fitSize: cardFitSize,
            avatar: store.state.profile.value?.user.avatar?.id
        )
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .clipped()
        .clipShape(.rect(cornerRadius: 22, style: .circular))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .circular)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            colors.background.brand.static,
                            .green.opacity(0.4),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 1),
                        endPoint: UnitPoint(x: 0.5, y: 97.0 / 281.0)
                    )
                )
        }
        .overlay {
            HStack {
                if let profile = store.state.profile.value {
                    VStack {
                        Spacer()
                        Text(profile.user.displayName)
                            .font(.medium(size: 28))
                            .foregroundStyle(colors.text.primary.staticLight)
                            .padding(.leading, 16)
                            .padding(.bottom, 14)
                    }
                }
                Spacer()
                VStack {
                    Spacer()
                    IconButton(
                        config: IconButton.Config(
                            style: .primary,
                            icon: .qrCode
                        )
                    ) {}.allowsHitTesting(false)
                }
                .padding([.bottom, .trailing], 10)
            }
        }
    }
    
    @ViewBuilder private var qrCodeCard: some View {
        colors.background.primary.alternative
            .overlay {
                GeometryReader { geometry in
                    let side = CGFloat(qrCodeSide(geometry: geometry))
                    let image = store.state.qrCodeData
                        .flatMap(Image.init(uiImage:))
                    if let image {
                        HStack(spacing: 0) {
                            Spacer()
                            VStack(spacing: 0) {
                                Spacer()
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .foregroundStyle(colors.text.primary.alternative)
                                    .frame(width: side, height: side)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .aspectRatio(cardAspectRatio, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 22, style: .circular))
            .overlay {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        IconButton(
                            config: IconButton.Config(
                                style: .primary,
                                icon: .question
                            )
                        ) {
                            store.dispatch(.onShowQrHintTap)
                        }
                    }
                    .padding([.bottom, .trailing], 10)
                }
            }
    }
    
    private var cardAspectRatio: CGFloat {
        cardFitSize.width / cardFitSize.height
    }
    
    private var cardFitSize: CGSize {
        CGSize(width: 371, height: 281)
    }
    
    private var tabTransitionOpacity: CGFloat {
        1 - abs(tabTransitionProgress)
    }
    
    private var tabTransitionOffset: CGFloat {
        28 * tabTransitionProgress
    }
    
    private func qrCodeSide(geometry: GeometryProxy) -> Int {
        Int(
            min(
                geometry.size.width / cardAspectRatio,
                geometry.size.height * cardAspectRatio
            )
        ) - 30 * 2
    }
    
    @ViewBuilder private var menuOptions: some View {
        VStack(spacing: 0) {
            MenuOption(
                config: MenuOption.Config(
                    style: .primary,
                    icon: .pencilFill,
                    title: .profileActionEditProfile,
                    accessoryIcon: .chevronRight
                )
            ) {
                store.dispatch(.onEditProfileTap)
            }
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 16)
                Text(.profileActionsTitle)
                    .foregroundStyle(colors.text.secondary.default)
                    .font(.bold(size: 13))
                Spacer()
            }
            .padding(.top, 19)
            .padding(.bottom, 9)
            MenuOption(
                config: MenuOption.Config(
                    style: .primary,
                    icon: .settingsFill,
                    title: .profileActionAccountSettings,
                    accessoryIcon: .chevronRight
                )
            ) {
                store.dispatch(.onEditProfileTap)
            }
            MenuOption(
                config: MenuOption.Config(
                    style: .primary,
                    icon: .bellFill,
                    title: .profileActionNotificationSettings,
                    accessoryIcon: .chevronRight
                )
            ) {
                store.dispatch(.onEditProfileTap)
            }
            .padding(.top, 2)
            Spacer()
        }
        .opacity(tabTransitionOpacity)
        .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
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
                        $0.avatarCardFlipCount = 1
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
