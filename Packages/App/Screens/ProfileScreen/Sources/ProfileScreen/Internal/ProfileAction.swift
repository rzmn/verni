import Foundation
import Domain
internal import DesignSystem

enum ProfileAction {
    case onEditProfileTap
    case onAccountSettingsTap
    case onNotificationsSettingsTap
    case onFlipAvatarTap
    case onLogoutTap
    case onNotificationsTap
    case onRefreshProfile
    case profileUpdated(Profile)
    
    case onShowQrHintTap
    case onRequestQrImage(size: Int)
    case onQrImageReady(Data)
    
    case unauthorized(reason: String)
}
