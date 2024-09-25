import UIKit
import Combine
import Domain
import AppBase
import SwiftUI
internal import DesignSystem
internal import Base

struct AddExpenseView: View {
    @StateObject var viewModel: AddExpenseViewModel

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
                    viewModel.state.expenseOwnership
                },
                set: { rule in
                    viewModel.handle(.onOwnershipSelected(rule: rule))
                }
            )
        ) {
            ForEach(viewModel.state.expenseOwnershipSelection) { rule in
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
                        viewModel.state.splitEqually
                    },
                    set: { isOn in
                        viewModel.handle(.onSplitRuleTap(equally: isOn))
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
        let model: AddExpenseViewModel
        private let host: UIHostingController<AddExpenseView>

        required init(model: AddExpenseViewModel) {
            self.model = model
            host = UIHostingController(rootView: AddExpenseView(viewModel: model))
        }

        var view: UIView {
            host.view
        }
    }
}

#Preview {
    AddExpenseView(
        viewModel: AddExpenseViewModel(
            state: AddExpenseState(
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
