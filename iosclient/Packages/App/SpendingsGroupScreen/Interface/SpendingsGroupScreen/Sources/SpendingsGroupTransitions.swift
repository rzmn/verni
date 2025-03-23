import AppBase

public struct SpendingsGroupTransitions {
    public let appear: ModalTransition
    public let tab: TabTransition

    public init(appear: ModalTransition, tab: TabTransition) {
        self.appear = appear
        self.tab = tab
    }
}
