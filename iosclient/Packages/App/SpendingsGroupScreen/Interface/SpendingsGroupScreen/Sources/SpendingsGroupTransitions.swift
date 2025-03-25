import AppBase

public struct SpendingsGroupTransitions {
    public let appear: ModalTransition
    public let tapOwnerTab: TapOwnerTabTransition
    public let tab: TabTransition

    public init(
        appear: ModalTransition,
        tapOwnerTab: TapOwnerTabTransition,
        tab: TabTransition
    ) {
        self.appear = appear
        self.tapOwnerTab = tapOwnerTab
        self.tab = tab
    }
}
