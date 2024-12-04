import AppBase

public struct AuthWelcomeTransitions {
    public let appear: ModalTransition
    public let dismiss: ModalTransition
    
    public init(appear: ModalTransition, dismiss: ModalTransition) {
        self.appear = appear
        self.dismiss = dismiss
    }
}
