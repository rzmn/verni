import SwiftUI
import AppBase

public struct FriendsView: View {
    private let executorFactory: any ActionExecutorFactory<FriendsAction>
    @ObservedObject private var store: Store<FriendsState, FriendsAction>

    init(
        executorFactory: any ActionExecutorFactory<FriendsAction>,
        store: Store<FriendsState, FriendsAction>
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
    FriendsView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: FriendsModel.initialState,
            reducer: FriendsModel.reducer
        )
    )
}
