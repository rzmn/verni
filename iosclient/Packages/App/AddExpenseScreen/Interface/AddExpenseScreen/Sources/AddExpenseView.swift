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
    
    public init(store: Store<AddExpenseState, AddExpenseAction>, transitions: AddExpenseTransitions) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
        }
        .background(colors.background.secondary.default)
        .keyboardDismiss()
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
                        let filtered = String(
                            newValue
                                .filter { $0.isNumber }
                                .drop(while: { $0 == "0" })
                        )
                        let formatted = filtered.isEmpty ? "0" : filtered
                        if formatted != textValue {
                            textValue = formatted
                        }
                        if let value = Decimal(string: formatted) {
                            withAnimation {
                                store.dispatch(.amountChanged(value))
                            }
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
                    withAnimation {
                        store.dispatch(.selectSplitRule(.equally))
                    }
                }
                .opacity(store.state.splitRule == .equally ? 1 : 0.5)
                .allowsHitTesting(store.state.splitRule != .equally)
                DesignSystem.Button(
                    config: .init(
                        style: .primary,
                        text: .addExpenseFull
                    )
                ) {
                    withAnimation {
                        store.dispatch(.selectSplitRule(.full))
                    }
                }
                .opacity(store.state.splitRule == .full ? 1 : 0.5)
                .allowsHitTesting(store.state.splitRule != .full)
            }
            if let counterparty = store.state.counterparty {
                ExpenseSharesPickerView(
                    store: store,
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
            CounterpartiesPickerView(store: store)
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
                    config: .button(
                        .init(
                            title: .addExpenseNavCancel,
                            enabled: true
                        )
                    ),
                    action: {
                        store.dispatch(.cancel)
                    }
                ),
                rightItem: .init(
                    config: .button(
                        .init(
                            title: .addExpenseNavSubmit,
                            enabled: store.state.canSubmit
                        )
                    ),
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
                transitions: AddExpenseTransitions()
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
