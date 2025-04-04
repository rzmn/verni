import Foundation
import Entities
import UIKit

public enum ProfileAction: Sendable {
    case onEditProfileTap
    case onAccountSettingsTap
    case onNotificationsSettingsTap
    case onFlipAvatarTap
    case onLogoutTap
    case onNotificationsTap
    case onShareTap
    case profileInfoUpdated(UserPayload)
    case profileUpdated(Profile)

    case onShowQrHintTap
    case onAppear
    case onRequestQrImage(size: Int)
    case onQrImageReady(UIImage)

    case unauthorized(reason: String)
}
