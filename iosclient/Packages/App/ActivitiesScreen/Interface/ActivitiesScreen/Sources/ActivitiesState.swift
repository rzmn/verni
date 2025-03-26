import Foundation
import Entities
import UIKit
internal import DesignSystem

public struct ActivitiesState: Equatable, Sendable {
    public var operations: [Entities.Operation]
    
    public init(operations: [Entities.Operation]) {
        self.operations = operations
    }
}
