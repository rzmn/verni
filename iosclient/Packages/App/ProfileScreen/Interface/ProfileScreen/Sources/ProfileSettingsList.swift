import SwiftUI
import AppBase
import Entities
internal import DesignSystem

struct ProfileSettingsList: View {
    @ObservedObject private var store: Store<ProfileState, ProfileAction>
    @Environment(ColorPalette.self) private var colors

    init(store: Store<ProfileState, ProfileAction>) {
        self.store = store
    }

    var body: some View {
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
                store.dispatch(.onAccountSettingsTap)
            }
            MenuOption(
                config: MenuOption.Config(
                    style: .primary,
                    icon: .bellFill,
                    title: .profileActionNotificationSettings,
                    accessoryIcon: .chevronRight
                )
            ) {
                store.dispatch(.onNotificationsSettingsTap)
            }
            .padding(.top, 2)
        }
    }
}

#if DEBUG

#Preview {
    ProfileSettingsList(
        store: Store(
            state: ProfileState(
                profile: Profile(
                    userId: "",
                    email: .undefined
                ),
                profileInfo: UserPayload(
                    displayName: "name",
                    avatar: nil
                ),
                avatarCardFlipCount: 0,
                qrCodeData: nil
            ),
            reducer: { state, _ in state }
        )
    )
    .debugBorder()
    .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
