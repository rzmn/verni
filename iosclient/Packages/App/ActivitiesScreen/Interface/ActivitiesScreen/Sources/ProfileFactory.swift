import AppBase

public protocol ActivitiesFactory: Sendable {
    func create() async -> any ScreenProvider<ActivitiesEvent, ActivitiesView, ActivitiesTransitions>
}
