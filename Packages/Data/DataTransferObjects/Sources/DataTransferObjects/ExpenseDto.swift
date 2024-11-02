import Base

public struct ExpenseDto: Codable, Sendable, Equatable {
    public let timestamp: Int64
    public let details: String
    public let total: CostDto
    public let currency: CurrencyDto
    public let shares: [ShareOfExpenseDto]
    public let attachments: [ExpenseAttachmentDto]

    public init(
        timestamp: Int64,
        details: String,
        cost: CostDto,
        currency: String,
        shares: [ShareOfExpenseDto],
        attachments: [ExpenseAttachmentDto]
    ) {
        self.timestamp = timestamp
        self.details = details
        self.total = cost
        self.currency = currency
        self.shares = shares
        self.attachments = attachments
    }
}
