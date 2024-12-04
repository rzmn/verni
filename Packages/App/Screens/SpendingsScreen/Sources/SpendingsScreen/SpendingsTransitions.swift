import AppBase

public struct SpendingsTransitions {
    public let appear: ModalTransition
    public let tab: TabTransition
    
    public init(appear: ModalTransition, tab: TabTransition) {
        self.appear = appear
        self.tab = tab
    }
}
