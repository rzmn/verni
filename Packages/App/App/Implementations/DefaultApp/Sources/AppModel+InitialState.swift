import App

extension AppModel {
    @MainActor static var initialState: AppState {
        .launching(LaunchingState(session: AnySharedAppSession(value: DefaultSharedAppSession())))
    }
}
