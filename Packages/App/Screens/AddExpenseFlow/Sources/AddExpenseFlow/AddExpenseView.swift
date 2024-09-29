import UIKit
import Combine
import Domain
import AppBase
import SwiftUI
internal import DesignSystem
internal import Base

struct AddExpenseView: View {
    @StateObject var store: Store<AddExpenseState, AddExpenseUserAction>

    var body: some View {
        VStack {
            expenseOwnershipPicker
                .padding(.top, 12)
            splitEquallyToggle
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder private var expenseOwnershipPicker: some View {
        Picker(
            selection: Binding(
                get: {
                    store.state.expenseOwnership
                },
                set: { rule in
                    store.handle(.onOwnershipSelected(rule: rule))
                }
            )
        ) {
            ForEach(store.state.expenseOwnershipSelection) { rule in
                switch rule {
                case .iAmOwned:
                    Text("expense_i_am_owed".localized)
                case .iOwe:
                    Text("expense_i_owe".localized)
                }
            }
        } label: {
            Text("label?")
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder private var splitEquallyToggle: some View {
        HStack {
            Toggle(
                isOn: Binding(
                    get: {
                        store.state.splitEqually
                    },
                    set: { isOn in
                        store.handle(.onSplitRuleTap(equally: isOn))
                    }
                )
            ) {}
            .labelsHidden()
            Text("expense_split_equally".localized)
            Spacer()
        }
    }
}

extension AddExpenseView {
    class Adapter: ViewProtocol {
        let model: Store<AddExpenseState, AddExpenseUserAction>
        private let host: UIHostingController<AddExpenseView>

        required init(model: Store<AddExpenseState, AddExpenseUserAction>) {
            self.model = model
            host = UIHostingController(rootView: AddExpenseView(store: model))
        }

        var view: UIView {
            host.view
        }
    }
}

#Preview {
    AddExpenseView(
        store: Store<AddExpenseState, AddExpenseUserAction>(
            current: AddExpenseState(
                currencies: [
                    .euro, .russianRuble, .unknown("BUB")
                ],
                counterparty: nil,
                selectedCurrency: .euro,
                expenseDescription: "expense description",
                amount: "123",
                splitEqually: true,
                expenseOwnership: .iOwe,
                expenseOwnershipSelection: [.iOwe, .iAmOwned],
                amountHint: nil,
                expenseDescriptionHint: nil
            ),
            handle: { _ in }
        )
    )
}
