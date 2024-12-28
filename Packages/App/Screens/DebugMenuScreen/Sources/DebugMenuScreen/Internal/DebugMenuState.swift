import Foundation
internal import DesignSystem

enum StackMember {
    case designSystem
    case buttons
    case colors
    case fonts
    case textFields
    case haptic
    case popups
}

struct DesignSystemState: Equatable, Sendable {
    enum Section: Int, Identifiable {
        case button
        case textField
        case colors
        case fonts
        case haptic
        case popups

        var id: Int {
            rawValue
        }
    }
    var sections: [Section]
    var section: Section?
}

struct DebugMenuState: Equatable, Sendable {
    enum Section: Equatable, Sendable, Identifiable {
        case designSystem(DesignSystemState)

        var id: String {
            switch self {
            case .designSystem:
                return "designSystem"
            }
        }
    }
    var navigation: [StackMember]
    var sections: [Section]
    var section: Section?
}
