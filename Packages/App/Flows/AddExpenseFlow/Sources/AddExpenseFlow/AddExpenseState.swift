import Domain
import AppBase

struct AddExpenseState: Equatable, Sendable {
    enum ExpenseOwnership: Equatable, Sendable, Identifiable {
        case iOwe
        case iAmOwned

        var id: ExpenseOwnership {
            self
        }
    }

    let currencies: [Currency]
    let counterparty: User?
    let selectedCurrency: Currency
    let expenseDescription: String
    let amount: String
    let splitEqually: Bool
    let expenseOwnership: ExpenseOwnership
    let expenseOwnershipSelection: [ExpenseOwnership]

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
