internal import DesignSystem

public enum DebugMenuAction: Sendable {
    case debugMenuSectionTapped(DebugMenuState.Section)
    case designSystemSectionTapped(DesignSystemState.Section)
    case updateNavigationStack([StackMember])
    case onTapBack
}
