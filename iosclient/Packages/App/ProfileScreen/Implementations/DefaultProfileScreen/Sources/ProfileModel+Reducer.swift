import ProfileScreen
internal import Convenience

extension ProfileModel {
    static var reducer: @MainActor (ProfileState, ProfileAction) -> ProfileState {
        return { state, action in
            switch action {
            case .onEditProfileTap:
                return state
            case .onAccountSettingsTap:
                return state
            case .onShareTap:
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
            case .onRequestQrImage:
                return state
            case .profileUpdated(let profile):
                return modify(state) {
                    $0.profile = profile
                }
            case .onQrImageReady(let data):
                return modify(state) {
                    $0.qrCodeData = data
                }
            case .onShowQrHintTap:
                return state
            case .unauthorized:
                return state
            case .onAppear:
                return state
            case .profileInfoUpdated(let info):
                return modify(state) {
                    $0.profileInfo = info
                }
            }
        }
    }
}
