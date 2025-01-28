import AppBase

public protocol SpendingsFactory: Sendable {
    func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions>
}
