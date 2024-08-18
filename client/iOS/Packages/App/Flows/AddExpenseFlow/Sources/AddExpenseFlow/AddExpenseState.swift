import Domain
import AppBase

struct AddExpenseState: Equatable {
    enum ExpenseOwnership: Equatable {
        case iOwe
        case iAmOwned
    }

    let currencies: [Currency]
    let counterparty: User?
    let selectedCurrency: Currency
    let expenseDescription: String
    let amount: String
    let splitEqually: Bool
    let expenseOwnership: ExpenseOwnership

    let amountHint: String?
    let expenseDescriptionHint: String?

    var canConfirm: Bool {
        guard !amount.isEmpty && !expenseDescription.isEmpty else {
            return false
        }
        guard amountHint == nil && expenseDescriptionHint == nil else {
            return false
        }
        guard counterparty != nil else {
            return false
        }
        return true
    }
}
