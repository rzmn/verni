import Foundation
import Entities
import UIKit
internal import DesignSystem

public struct UserPreviewState: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case me
        case haveGroupInCommon(SpendingGroup.Identifier, balance: [Currency: Amount])
        case noStatus
    }
    
    public var user: User
    public var status: Status
    
    public init(
        user: User,
        status: Status
    ) {
        self.user = user
        self.status = status
    }
}
