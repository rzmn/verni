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
            colors.background.primary.default
                .aspectRatio(371.0 / 281.0, contentMode: .fit)
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
                        .padding(.all, 2)
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
                            ) {
                                store.dispatch(.onFlipAvatarTap)
                            }
                        }
                        .padding([.bottom, .trailing], 12)
                    }
                }
                .background(
                    Rectangle()
                        .foregroundStyle(colors.background.secondary.default)
                        .padding(.bottom, 22)
                )
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
            guard case .initial = store.state.profile else {
                return
            }
            store.dispatch(.onRefreshProfile)
        }
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
                            avatar: nil
                        ),
                        email: "email@verni.co",
                        isEmailVerified: false
                    )
                )
            },
            reducer: ProfileModel.reducer
        )
    )
    .environment(ColorPalette.light)
    .preview(packageClass: ProfileModel.self)
}
