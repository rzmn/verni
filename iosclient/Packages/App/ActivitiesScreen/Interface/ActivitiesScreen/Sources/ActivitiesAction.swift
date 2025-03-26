import Foundation
import Entities
import UIKit

public enum ActivitiesAction: Sendable {
    case cancel
    case appeared
    case onDataUpdated([Entities.Operation])
}
