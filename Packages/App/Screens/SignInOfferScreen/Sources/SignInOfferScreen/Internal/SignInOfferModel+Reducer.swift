extension SignInOfferModel {
    static var reducer: @MainActor (SignInOfferState, SignInOfferAction) -> SignInOfferState {
        return { state, action in
            switch action {
            case .onSignInTap:
                return state
            }
        }
    }
}
