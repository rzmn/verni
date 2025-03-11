import SwiftUI
import Entities
import AppBase
internal import Convenience
internal import DesignSystem

public struct AddExpenseView: View {
    @ObservedObject var store: Store<AddExpenseState, AddExpenseAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    @State private var textValue: String = "0"
    @Binding private var tabTransitionProgress: CGFloat
    
    public init(store: Store<AddExpenseState, AddExpenseAction>, transitions: AddExpenseTransitions) {
        self.store = store
        _tabTransitionProgress = transitions.modal.progress
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
        }
        .background(colors.background.secondary.default)
    }
    
    private var content: some View {
        VStack {
            Spacer()
                .frame(height: 16)
            TextField(
                "0",
                text: Binding(
                    get: {
                        textValue
                    },
                    set: { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        let formatted = filtered.isEmpty ? "0" : filtered
                        if formatted != newValue {
                            textValue = filtered
                        }
                        if let value = Decimal(string: formatted) {
                            store.dispatch(.amountChanged(value))
                        }
                    }
                )
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.medium(size: 40))
            .foregroundStyle(colors.text.primary.default)
            .overlay(
                HStack(spacing: 0) {
                    Text(store.state.currency.sign)
                        .multilineTextAlignment(.center)
                        .font(.medium(size: 40))
                        .opacity(0)
                    Text(textValue)
                        .multilineTextAlignment(.center)
                        .font(.medium(size: 40))
                        .opacity(0)
                    Text(store.state.currency.sign)
                        .multilineTextAlignment(.center)
                        .font(.medium(size: 40))
                        .foregroundStyle(colors.text.primary.default)
                        .opacity(0.5)
                }
            )
            .frame(height: 66)
            .background(colors.background.secondary.default)
            .clipShape(.rect(cornerRadius: 16))
            HStack {
                DesignSystem.Button(
                    config: .init(
                        style: .primary,
                        text: .addExpenseSplitEqually
                    )
                ) {
                    store.dispatch(.selectSplitRule(.equally))
                }
                DesignSystem.Button(
                    config: .init(
                        style: .primary,
                        text: .addExpenseFull
                    )
                ) {
                    store.dispatch(.selectSplitRule(.full))
                }
            }
            if let counterparty = store.state.counterparty {
                ExpenseSharesPickerView(
                    store: store,
                    host: store.state.host,
                    counterparty: counterparty
                )
            }
            DesignSystem.TextField(
                text: Binding(
                    get: {
                        store.state.title
                    },
                    set: { value in
                        store.dispatch(.titleChanged(value))
                    }
                ),
                config: .init(
                    placeholder: .addExpenseTitlePlaceholder
                )
            )
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(colors.background.primary.default)
        .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
        .ignoresSafeArea(edges: [.bottom])
    }
    
    private var navigationBar: some View {
        NavigationBar(
            config: NavigationBar.Config(
                leftItem: .init(
                    config: .button(.addExpenseNavCancel),
                    action: {
                        store.dispatch(.cancel)
                    }
                ),
                rightItem: .init(
                    config: .button(.addExpenseNavSubmit),
                    action: {
                        store.dispatch(.submit)
                    }
                ),
                title: .addExpenseNavTitle,
                style: .primary
            )
        )
    }
}

#if DEBUG

private struct AddExpensePreview: View {
    @State var tabTransition: CGFloat = 0
    
    var body: some View {
        ZStack {
            AddExpenseView(
                store: Store(
                    state: AddExpenseState(
                        currency: .russianRuble,
                        amount: 123,
                        splitRule: .equally,
                        paidByHost: true,
                        title: "expense",
                        host: .previewHost,
                        counterparty: .previewCounterparty,
                        availableCounterparties: []
                    ),
                    reducer: { state, _ in state }
                ),
                transitions: AddExpenseTransitions(
                    modal: ModalTransition(
                        progress: .constant(0),
                        sourceOffset: .constant(0),
                        destinationOffset: .constant(0)
                    )
                )
            )
        }
    }
}

#Preview {
    AddExpensePreview()
        .environment(ColorPalette.dark)
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
