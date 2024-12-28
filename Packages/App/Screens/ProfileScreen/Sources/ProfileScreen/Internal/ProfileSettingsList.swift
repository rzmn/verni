import SwiftUI
import AppBase
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
        }
    }
}

#Preview {
    ProfileSettingsList(
        store: Store(
            state: ProfileModel.initialState,
            reducer: ProfileModel.reducer
        )
    )
    .debugBorder()
    .preview(packageClass: ProfileModel.self)
}
