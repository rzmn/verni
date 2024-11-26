import Foundation
internal import DesignSystem

struct LogInState: Equatable, Sendable {
    var email: String
    var password: String
    
    var canSubmitCredentials: Bool
    var bottomSheet: AlertBottomSheetPreset?
}
