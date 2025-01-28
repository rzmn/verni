import Foundation
import DesignSystem

public struct LogInState: Equatable, Sendable {
    public var email: String
    public var password: String

    public var canSubmitCredentials: Bool
    public var bottomSheet: AlertBottomSheetPreset?
    
    public init(
        email: String,
        password: String,
        canSubmitCredentials: Bool,
        bottomSheet: AlertBottomSheetPreset?
    ) {
        self.email = email
        self.password = password
        self.canSubmitCredentials = canSubmitCredentials
        self.bottomSheet = bottomSheet
    }
}
