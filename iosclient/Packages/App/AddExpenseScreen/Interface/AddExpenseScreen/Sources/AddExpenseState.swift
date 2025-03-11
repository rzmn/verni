import Foundation
import Entities
import UIKit
internal import DesignSystem

public struct AddExpenseState: Equatable, Sendable {
    public var currency: Currency
    public var amount: Amount
    public var splitRule: SplitRule
    public var paidByHost: Bool
    public var title: String
    public var host: User
    public var counterparty: User?
    public var availableCounterparties: [User]
    
    public init(
        currency: Currency,
        amount: Amount,
        splitRule: SplitRule,
        paidByHost: Bool,
        title: String,
        host: User,
        counterparty: User?,
        availableCounterparties: [User]
    ) {
        self.currency = currency
        self.amount = amount
        self.splitRule = splitRule
        self.paidByHost = paidByHost
        self.title = title
        self.host = host
        self.counterparty = counterparty
        self.availableCounterparties = availableCounterparties
    }
}
