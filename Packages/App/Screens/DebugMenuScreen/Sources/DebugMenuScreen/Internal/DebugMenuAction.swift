internal import DesignSystem

enum DebugMenuAction {
    case debugMenuSectionTapped(DebugMenuState.Section)
    case designSystemSectionTapped(DesignSystemState.Section)
    case updateNavigationStack([StackMember])
    case onTapBack
}
