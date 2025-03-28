import AppLayer

extension DefaultAppModel {
    @MainActor static var initialState: AppState {
        .launching(LaunchingState(session: AnySharedAppSession(value: DefaultSharedAppSession())))
    }
}
