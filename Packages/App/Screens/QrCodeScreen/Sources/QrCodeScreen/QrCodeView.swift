import SwiftUI
import AppBase

public struct QrCodeView: View {
    private let executorFactory: any ActionExecutorFactory<QrCodeAction>
    @ObservedObject private var store: Store<QrCodeState, QrCodeAction>

    init(
        executorFactory: any ActionExecutorFactory<QrCodeAction>,
        store: Store<QrCodeState, QrCodeAction>
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
    QrCodeView(
        executorFactory: FakeActionExecutorFactory(),
        store: Store(
            state: QrCodeModel.initialState,
            reducer: QrCodeModel.reducer
        )
    )
}
