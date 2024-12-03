import Foundation
import Domain
import UIKit
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
    case onQrImageReady(UIImage)
    
    case unauthorized(reason: String)
}
