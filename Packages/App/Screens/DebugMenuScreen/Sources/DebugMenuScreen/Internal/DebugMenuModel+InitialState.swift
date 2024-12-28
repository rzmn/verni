extension DebugMenuModel {
    static var initialState: DebugMenuState {
        DebugMenuState(
            navigation: [],
            sections: [
                .designSystem(Self.initialDesignSystemState)
            ]
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
            ]
        )
    }
}
