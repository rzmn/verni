import SwiftUI
import AppBase

public struct UserPreviewView: View {
    private let executorFactory: any ActionExecutorFactory<UserPreviewAction>
    @ObservedObject private var store: Store<UserPreviewState, UserPreviewAction>

    init(
        executorFactory: any ActionExecutorFactory<UserPreviewAction>,
        store: Store<UserPreviewState, UserPreviewAction>
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
    UserPreviewView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: UserPreviewModel.initialState,
            reducer: UserPreviewModel.reducer
        )
    )
}
