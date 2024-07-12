import Domain
import DI

actor MainModel {
    private lazy var presenter = MainPresenter(model: self, appRouter: appRouter)
    private let appRouter: AppRouter
    private weak var appModel: AppModel?
    let friendsModel: FriendsModel
    let accountModel: AccountModel

    init(di: ActiveSessionDIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        friendsModel = await FriendsModel(di: di, appRouter: appRouter)
        accountModel = await AccountModel(di: di, appRouter: appRouter)
        await friendsModel.setMainModel(self)
    }

    func setAppModel(_ appModel: AppModel) async {
        self.appModel = appModel
        await accountModel.setAppModel(appModel)
    }

    @MainActor
    func start() async {
        await presenter.start()
    }

    func logout() async {
        await appModel?.logout()
    }
}

extension MainModel: UrlResolver {
    func resolve(url: InternalUrl) async {
        switch url {
        case .users(let users):
            switch users {
            case .show(let uid):
                await friendsModel.showUser(uid: uid)
            }
        }
    }
}
