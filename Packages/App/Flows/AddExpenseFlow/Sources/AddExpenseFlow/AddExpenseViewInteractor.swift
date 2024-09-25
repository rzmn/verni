import Foundation
import Combine
import Domain

@MainActor class AddExpenseViewInteractor {
    typealias ExpenseOwnership = AddExpenseState.ExpenseOwnership

    @Published var state: AddExpenseState

    @Published var splitEqually: Bool
    @Published var expenseOwnership: ExpenseOwnership
    @Published var counterparty: User?
    @Published var description: String
    @Published var amount: String
    @Published var amountHint: String?
    @Published var expenseDescriptionHint: String?

    init(counterparty: User?) async {
        let initial = AddExpenseState(
            currencies: [
                .russianRuble,
                .euro,
                .usDollar
            ],
            counterparty: counterparty,
            selectedCurrency: .russianRuble,
            expenseDescription: "",
            amount: "",
            splitEqually: true,
            expenseOwnership: .iOwe,
            expenseOwnershipSelection: [.iOwe, .iAmOwned],
            amountHint: nil,
            expenseDescriptionHint: nil
        )
        state = initial
        splitEqually = initial.splitEqually
        expenseOwnership = initial.expenseOwnership
        self.counterparty = initial.counterparty
        description = initial.expenseDescription
        amount = initial.amount
        amountHint = initial.amountHint
        expenseDescriptionHint = initial.expenseDescriptionHint
        setupStateBuilder(initialState: initial)
    }

    private func setupStateBuilder(initialState: AddExpenseState) {
        $description
            .map { description -> String? in
                guard !description.isEmpty else {
                    return "expense_description_should_not_be_empty".localized
                }
                return nil
            }
            .assign(to: &$expenseDescriptionHint)
        $amount
            .map { amount -> String? in
                guard let value = try? Cost(amount, format: .number) else {
                    return "expense_invalid_number".localized
                }
                guard value > 0 else {
                    return "expense_number_should_be_nonzero".localized
                }
                return nil
            }
            .assign(to: &$amountHint)

        Publishers.CombineLatest3(
            Publishers.CombineLatest3($splitEqually, $expenseOwnership, $counterparty),
            Publishers.CombineLatest($description, $amount),
            Publishers.CombineLatest($amountHint, $expenseDescriptionHint)
        ).map { value in
            let (
                (splitEqually, expenseOwnership, counterparty),
                (description, amount),
                (amountHint, descriptionHint)
            ) = value

            return AddExpenseState(
                currencies: [
                    .russianRuble,
                    .euro,
                    .usDollar
                ],
                counterparty: counterparty,
                selectedCurrency: .russianRuble,
                expenseDescription: description,
                amount: amount,
                splitEqually: splitEqually,
                expenseOwnership: expenseOwnership,
                expenseOwnershipSelection: initialState.expenseOwnershipSelection,
                amountHint: amountHint,
                expenseDescriptionHint: descriptionHint
            )
        }
        .removeDuplicates()
        .receive(on: RunLoop.main)
        .assign(to: &$state)
    }
}
