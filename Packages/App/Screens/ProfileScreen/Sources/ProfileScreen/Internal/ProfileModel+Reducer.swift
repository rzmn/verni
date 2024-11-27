internal import Base

extension ProfileModel {
    static var reducer: @MainActor (ProfileState, ProfileAction) -> ProfileState {
        return { state, action in
            switch action {
            case .onEditProfileTap:
                return state
            case .onAccountSettingsTap:
                return state
            case .onNotificationsSettingsTap:
                return state
            case .onFlipAvatarTap:
                return state
            case .onLogoutTap:
                return state
            case .onNotificationsTap:
                return state
            case .onLogoutConfirmTap:
                return state
            case .onRefreshProfile:
                return state
            }
        }
    }
}
