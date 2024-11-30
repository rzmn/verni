import SwiftUI
import AppBase
import Domain
internal import DesignSystem
internal import Base

public struct ProfileView: View {
    @ObservedObject var store: Store<ProfileState, ProfileAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    init(store: Store<ProfileState, ProfileAction>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconButton(
                    config: IconButton.Config(
                        style: .primary,
                        icon: .bellBorder
                    )
                ) {
                    store.dispatch(.onNotificationsTap)
                }
                Spacer()
                IconButton(
                    config: IconButton.Config(
                        style: .primary,
                        icon: .logout
                    )
                ) {
                    store.dispatch(.onLogoutTap)
                }
            }
            .frame(height: 54)
            .overlay {
                Text(.profileTitle)
                    .font(.medium(size: 15))
                    .foregroundStyle(colors.text.primary.default)
            }
            .background(colors.background.secondary.default)
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
            .padding(.top, 2)
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 16)
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 16)
                    Text(.profileActionsTitle)
                        .foregroundStyle(colors.text.secondary.default)
                        .font(.bold(size: 13))
                }
                Spacer()
            }
            .frame(height: 39)
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
            .padding(.top, 2)
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
        .background(colors.background.primary.default)
        .onAppear {
            store.dispatch(.onRequestQrImage(size: Int(qrCodeSize * UIScreen.main.scale)))
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
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
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
                            .padding([.leading, .bottom], 16)
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
                .padding([.bottom, .trailing], 12)
            }
        }
    }
    
    @ViewBuilder private var qrCodeCard: some View {
        Color.white
            .aspectRatio(cardAspectRatio, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                let image = store.state.qrCodeData
                    .flatMap(UIImage.init(data:))
                    .map(Image.init(uiImage:))
                if let image {
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: qrCodeSize, height: qrCodeSize)
                }
            }
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
                    .padding([.bottom, .trailing], 12)
                }
            }
    }
    
    private var cardAspectRatio: CGFloat {
        cardFitSize.width / cardFitSize.height
    }
    
    private var cardFitSize: CGSize {
        CGSize(width: 371, height: 281)
    }
    
    private var qrCodeSize: CGFloat {
        170
    }
}

#Preview {
    ProfileView(
        store: Store(
            state: modify(ProfileModel.initialState) {
                $0.profile = .loaded(
                    Profile(
                        user: User(
                            id: "",
                            status: .currentUser,
                            displayName: "display name",
                            avatar: Avatar(id: "123")
                        ),
                        email: "email@verni.co",
                        isEmailVerified: false
                    )
                )
                $0.avatarCardFlipCount = 1
            },
            reducer: ProfileModel.reducer
        )
    )
    .environment(ColorPalette.dark)
    .preview(packageClass: ProfileModel.self)
}
