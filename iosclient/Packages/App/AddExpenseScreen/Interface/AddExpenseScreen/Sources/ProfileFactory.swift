import AppBase

public protocol AddExpenseFactory: Sendable {
    func create() async -> any ScreenProvider<AddExpenseEvent, AddExpenseView, AddExpenseTransitions>
}
