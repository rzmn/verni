import AppBase

@MainActor class UpdateAvatarPresenter: Presenter {
    let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    func presentWrongFormat() {
        router.hudFailure(description: "wrong_format_hint".localized)
    }
}
