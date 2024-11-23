internal import Base

extension LogInModel {
    static var reducer: @MainActor (LogInState, LogInAction) -> LogInState {
        return { state, action in
            switch action {
            case .onTapBack:
                return state
            case .passwordTextChanged(let text):
                return modify(state) {
                    $0.password = text
                }
            case .emailTextChanged(let text):
                return modify(state) {
                    $0.email = text
                }
            case .onCreateAccountTap:
                return state
            case .onLogInTap:
                return state
            }
        }
    }
}
