import Foundation
import Domain
internal import DesignSystem

struct ProfileState: Equatable, Sendable {
    enum ProfileLoadingFailureReason: Equatable, Sendable {
        case noInternet
    }
    var profile: Loadable<Profile, ProfileLoadingFailureReason>
}
