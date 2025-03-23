import AppBase

public protocol SpendingsGroupFactory: Sendable {
    func create() async -> any ScreenProvider<SpendingsGroupEvent, SpendingsGroupView, SpendingsGroupTransitions>
}
