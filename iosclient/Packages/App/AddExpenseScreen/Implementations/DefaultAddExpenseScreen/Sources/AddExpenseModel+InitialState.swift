import AddExpenseScreen
import Entities

extension AddExpenseModel {
    static func initialState(host: User, counterparties: [User]) -> AddExpenseState {
        AddExpenseState(
            currency: .russianRuble,
            amount: 0,
            splitRule: .equally,
            paidByHost: true,
            title: "",
            host: host,
            counterparty: nil,
            availableCounterparties: counterparties            
        )
    }
}
