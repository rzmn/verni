import Foundation
import Entities
import UIKit

public enum UserPreviewAction: Sendable {
    case appeared
    case infoUpdated(User)
    case createSpendingGroup
    case spendingGroupCreated(SpendingGroup.Identifier)
    case close
}
