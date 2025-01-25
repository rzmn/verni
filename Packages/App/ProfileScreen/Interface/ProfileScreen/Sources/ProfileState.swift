import Foundation
import Entities
import UIKit
internal import DesignSystem

public struct ProfileState: Equatable, Sendable {
    public var profile: Profile
    public var profileInfo: User
    public var avatarCardFlipCount: CGFloat
    public var qrCodeData: UIImage?
    
    public init(
        profile: Profile,
        profileInfo: User,
        avatarCardFlipCount: CGFloat,
        qrCodeData: UIImage?
    ) {
        self.profile = profile
        self.profileInfo = profileInfo
        self.avatarCardFlipCount = avatarCardFlipCount
        self.qrCodeData = qrCodeData
    }
}
