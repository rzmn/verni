import Foundation
import Domain
internal import DesignSystem

enum ProfileAction {
    case onEditProfileTap
    case onAccountSettingsTap
    case onNotificationsSettingsTap
    case onFlipAvatarTap
    case onShowQrHintTap
    case onLogoutTap
    case onNotificationsTap
    case onLogoutConfirmTap
    case onRefreshProfile
    case profileUpdated(Profile)
    case showQrHint(show: Bool)
    case onRequestQrImage(size: Int)
    case onQrImageReady(Data)
    
    case unauthorized(reason: String)
}
