import AppBase

public struct ActivitiesTransitions {
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
