import Foundation

public struct SpendingsPreview {
    let counterparty: User.ID
    let balance: [Currency: Decimal]
}
