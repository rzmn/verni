import Foundation
import Entities

public enum PushContent: Sendable {
    public struct SpendingCreated: Sendable {
        public let spendingName: String
        public let groupName: String?
        public let amount: Amount
        public let currency: Currency
        
        public init(
            spendingName: String,
            groupName: String?,
            amount: Amount,
            currency: Currency
        ) {
            self.spendingName = spendingName
            self.groupName = groupName
            self.amount = amount
            self.currency = currency
        }
    }
    
    public struct SpendingGroupCreated: Sendable {
        public let groupName: String?
        
        public init(groupName: String?) {
            self.groupName = groupName
        }
    }
    
    case spendingCreated(SpendingCreated)
    case spendingGroupCreated(SpendingGroupCreated)
}

public enum ProcessPushError: Error, Sendable {
    case internalError(Error)
}

public protocol ReceivingPushUseCase: Sendable {
    @MainActor func handle(
        rawPushPayload: [AnyHashable: Any]
    ) async throws(ProcessPushError) -> PushContent
}
