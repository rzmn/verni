import DebugMenuScreen

extension DebugMenuModel {
    static var initialState: DebugMenuState {
        DebugMenuState(
            navigation: [],
            sections: [
                .designSystem(Self.initialDesignSystemState)
            ],
            section: nil
        )
    }

    static var initialDesignSystemState: DesignSystemState {
        DesignSystemState(
            sections: [
                .button,
                .colors,
                .fonts,
                .textField,
                .haptic,
                .popups
            ],
            section: nil
        )
    }
}
