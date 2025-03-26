import AppBase

public struct ActivitiesTransitions {
    public let tapOwnerTab: TapOwnerTabTransition
    
    public init(
        tapOwnerTab: TapOwnerTabTransition
    ) {
        self.tapOwnerTab = tapOwnerTab
    }
}
