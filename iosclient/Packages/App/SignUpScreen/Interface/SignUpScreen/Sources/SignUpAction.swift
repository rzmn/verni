import Entities
import DesignSystem

public enum SignUpAction<Session: Sendable>: Sendable {
    case onTapBack
    case emailTextChanged(String)
    case emailHintChanged(String?)
    case passwordTextChanged(String)
    case passwordHintChanged(String?)
    case passwordRepeatTextChanged(String)
    case passwordRepeatHintChanged(String?)
    
    case canSubmitCredentialsChanged(Bool)
    
    case onSignUpTap
    case onSigningUpStarted
    case onSigningUpFailed
    case onUpdateBottomSheet(AlertBottomSheetPreset?)
    case signUp(Session)
}
