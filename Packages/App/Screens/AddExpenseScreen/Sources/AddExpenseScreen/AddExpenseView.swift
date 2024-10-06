import SwiftUI
import AppBase

public struct AddExpenseView: View {
    private let executorFactory: any ActionExecutorFactory<AddExpenseAction>
    @ObservedObject private var store: Store<AddExpenseState, AddExpenseAction>

    init(
        executorFactory: any ActionExecutorFactory<AddExpenseAction>,
        store: Store<AddExpenseState, AddExpenseAction>
    ) {
        self.executorFactory = executorFactory
        self.store = store
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    store.with(executorFactory).dispatch(.onLogoutTap)
                } label: {
                    Text(verbatim: .l10n.authSignIn)
                }
                .buttonStyle(type: .destructive, enabled: true)
                Spacer()
            }
        }
        .background(Color.palette.background)
    }
}

#Preview {
    AddExpenseView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: AddExpenseModel.initialState,
            reducer: AddExpenseModel.reducer
        )
    )
}
