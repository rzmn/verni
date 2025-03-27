import Foundation
import Entities
import UIKit
internal import DesignSystem

public struct ActivitiesState: Equatable, Sendable {
    public var operations: [Entities.Operation]
    public var sessionId: UUID
    
    public init(
        operations: [Entities.Operation],
        sessionId: UUID
    ) {
        self.operations = operations
        self.sessionId = sessionId
    }
}
