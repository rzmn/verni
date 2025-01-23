import Foundation
import Domain
import UIKit
internal import DesignSystem

struct ProfileState: Equatable, Sendable {
    enum ProfileLoadingFailureReason: Equatable, Sendable {
        case noInternet
    }
    var profile: Loadable<Profile, ProfileLoadingFailureReason>
    var avatarCardFlipCount: CGFloat
    var qrCodeData: UIImage?
}
