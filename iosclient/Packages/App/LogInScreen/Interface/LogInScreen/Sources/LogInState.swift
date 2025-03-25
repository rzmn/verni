import Foundation
import DesignSystem

public struct LogInState: Equatable, Sendable {
    public var email: String
    public var emailHint: String?
    
    public var password: String
    public var passwordHint: String?

    public var logInInProgress: Bool
    
    public var bottomSheet: AlertBottomSheetPreset?
    public var sessionId: UUID
    
    public init(
        email: String,
        emailHint: String? = nil,
        password: String,
        passwordHint: String? = nil,
        logInInProgress: Bool,
        bottomSheet: AlertBottomSheetPreset? = nil,
        sessionId: UUID
    ) {
        self.email = email
        self.emailHint = emailHint
        self.password = password
        self.passwordHint = passwordHint
        self.logInInProgress = logInInProgress
        self.bottomSheet = bottomSheet
        self.sessionId = UUID()
    }
}
