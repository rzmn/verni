extension QrCodeModel {
    static var reducer: @MainActor (QrCodeState, QrCodeAction) -> QrCodeState {
        return { state, action in
            switch action {
            case .onLogoutTap:
                return state
            }
        }
    }
}
