import SwiftUI
import AppBase

public struct AccountView: View {
    private let executorFactory: any ActionExecutorFactory<AccountAction>
    @ObservedObject private var store: Store<AccountState, AccountAction>

    init(
        executorFactory: any ActionExecutorFactory<AccountAction>,
        store: Store<AccountState, AccountAction>
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
                    Text("login_go_to_signin".localized)
                }
                .buttonStyle(type: .destructive, enabled: true)
                Spacer()
            }
        }
        .background(Color.palette.background)
    }
}

#Preview {
    AccountView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: AccountModel.initialState,
            reducer: AccountModel.reducer
        )
    )
}
