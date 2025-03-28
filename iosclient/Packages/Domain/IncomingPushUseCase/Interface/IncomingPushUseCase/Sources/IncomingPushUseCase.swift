import Foundation
import Entities

public enum PushContent: Sendable {
    public enum GroupName: Sendable {
        case opponentName(String)
        case groupName(String)
    }
    
    public struct SpendingCreated: Sendable {
        public let spendingName: String
        public let groupName: GroupName?
        public let amount: Amount
        public let currency: Currency
        public let share: Amount
        
        public init(
            spendingName: String,
            groupName: GroupName?,
            amount: Amount,
            currency: Currency,
            share: Amount
        ) {
            self.spendingName = spendingName
            self.groupName = groupName
            self.amount = amount
            self.currency = currency
            self.share = share
        }
    }
    
    public struct SpendingGroupCreated: Sendable {
        public let groupName: GroupName?
        
        public init(groupName: GroupName?) {
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
