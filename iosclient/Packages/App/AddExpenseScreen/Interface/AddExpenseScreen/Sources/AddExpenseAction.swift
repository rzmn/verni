import Foundation
import Entities
import UIKit

public enum AddExpenseAction: Sendable {
    case selectSplitRule(SplitRule)
    case amountChanged(Amount)
    case titleChanged(String)
    case paidByHostToggled
    case cancel
    case submit
    case expenseAdded
    case errorOccured(String)
    case selectCounterparty(User.Identifier?)
}
