import AppBase

class UpdateAvatarFlowPresenter: Presenter {
    let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    @MainActor
    func presentWrongFormat() {
        router.hudFailure(description: "wrong_format_hint".localized)
    }
}
