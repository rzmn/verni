internal import Base

extension DebugMenuModel {
    static var reducer: @MainActor (DebugMenuState, DebugMenuAction) -> DebugMenuState {
        return { state, action in
            switch action {
            case .debugMenuSectionTapped(let section):
                switch section {
                case .designSystem:
                    return modify(state) { state in
                        state.navigation = [.designSystem]
                        state.section = section
                    }
                }
            case .designSystemSectionTapped(let section):
                switch section {
                case .button:
                    return modify(state) { state in
                        state.navigation.append(.buttons)
                    }
                case .textField:
                    return modify(state) { state in
                        state.navigation.append(.textFields)
                    }
                case .colors:
                    return modify(state) { state in
                        state.navigation.append(.colors)
                    }
                case .fonts:
                    return modify(state) { state in
                        state.navigation.append(.fonts)
                    }
                }
            case .updateNavigationStack(let stack):
                return modify(state) { state in
                    state.navigation = stack
                }
            case .onTapBack:
                return modify(state) { state in
                    var navigation = state.navigation
                    _ = navigation.popLast()
                    if navigation.isEmpty {
                        state.section = nil
                    }
                    state.navigation = navigation
                }
            }
        }
    }
}
