import AppBase
import DI

public protocol AddExpenseFactory: Sendable {
    func create() async -> any ScreenProvider<AddExpenseEvent, AddExpenseView>
}

public final class DefaultAddExpenseFactory: AddExpenseFactory {
    private let di: ActiveSessionDIContainer

    public init(di: ActiveSessionDIContainer) async {
        self.di = di
    }

    public func create() async -> any ScreenProvider<AddExpenseEvent, AddExpenseView> {
        await AddExpenseModel(di: di)
    }
}
