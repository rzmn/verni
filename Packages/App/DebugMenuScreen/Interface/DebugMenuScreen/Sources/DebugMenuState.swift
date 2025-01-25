import Foundation
internal import DesignSystem

public enum StackMember: Sendable, Hashable {
    case designSystem(DesignSystemState)
    case buttons
    case colors
    case fonts
    case textFields
    case haptic
    case popups
}

public struct DesignSystemState: Hashable, Sendable {
    public enum Section: Int, Identifiable, Sendable {
        case button
        case textField
        case colors
        case fonts
        case haptic
        case popups

        public var id: Int {
            rawValue
        }
    }
    public var sections: [Section]
    public var section: Section?
    
    public init(
        sections: [Section],
        section: Section?
    ) {
        self.sections = sections
        self.section = section
    }
}

public struct DebugMenuState: Equatable, Sendable {
    public enum Section: Equatable, Sendable, Identifiable {
        case designSystem(DesignSystemState)

        public var id: String {
            switch self {
            case .designSystem:
                return "designSystem"
            }
        }
    }
    public var navigation: [StackMember]
    public var sections: [Section]
    public var section: Section?
    
    public init(
        navigation: [StackMember],
        sections: [Section],
        section: Section?
    ) {
        self.navigation = navigation
        self.sections = sections
        self.section = section
    }
}
