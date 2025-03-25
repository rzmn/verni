import AppBase

public struct ProfileEditingTransitions {
    public let tab: TabTransition
    public let tapOwnerTab: TapOwnerTabTransition

    public init(
        tab: TabTransition,
        tapOwnerTab: TapOwnerTabTransition
    ) {
        self.tab = tab
        self.tapOwnerTab = tapOwnerTab
    }
}
