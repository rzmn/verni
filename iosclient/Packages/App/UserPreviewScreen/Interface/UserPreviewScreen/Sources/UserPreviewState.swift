import Foundation
import Entities
import UIKit
internal import DesignSystem

public struct UserPreviewState: Equatable, Sendable {
    public var user: User
    
    public init(
        user: User
    ) {
        self.user = user
    }
}
