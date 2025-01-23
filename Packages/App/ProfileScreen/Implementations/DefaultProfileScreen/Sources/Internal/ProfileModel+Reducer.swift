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
                return modify(state) {
                    $0.avatarCardFlipCount += 1
                }
            case .onLogoutTap:
                return state
            case .onNotificationsTap:
                return state
            case .onRefreshProfile:
                return state
            case .onRequestQrImage:
                return state
            case .profileUpdated(let profile):
                return modify(state) {
                    $0.profile = .loaded(profile)
                }
            case .onQrImageReady(let data):
                return modify(state) {
                    $0.qrCodeData = data
                }
            case .onShowQrHintTap:
                return state
            case .unauthorized:
                return state
            }
        }
    }
}
