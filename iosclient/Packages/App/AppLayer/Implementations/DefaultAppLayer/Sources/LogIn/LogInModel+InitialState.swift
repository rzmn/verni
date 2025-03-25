import LogInScreen
import Foundation

extension LogInModel {
    static var initialState: LogInState {
        LogInState(
            email: "",
            password: "",
            logInInProgress: false,
            sessionId: UUID()
        )
    }
}
