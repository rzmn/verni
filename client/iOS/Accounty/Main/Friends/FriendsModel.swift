import Combine
import Domain
import DI
import DesignSystem

actor FriendsModel {
    let subject = CurrentValueSubject<FriendsState, Never>(FriendsState(content: .initial))

    private let appRouter: AppRouter
    private let friendListRepository: FriendsRepository
    private let usersRepository: UsersRepository
    private let di: ActiveSessionDIContainer
    private var subscriptions = Set<AnyCancellable>()
    private weak var mainModel: MainModel?

    init(di: ActiveSessionDIContainer, appRouter: AppRouter) async {
        self.di = di
        friendListRepository = di.friendListRepository()
        usersRepository = di.authorizedSessionRepository()
        self.appRouter = appRouter
    }

    func setMainModel(_ model: MainModel) {
        mainModel = model
    }

    func start() async {
        friendListRepository.friendsUpdated
            .sink { _ in
                Task {
                    await self.refresh()
                }
            }
            .store(in: &subscriptions)
    }

    func refresh() async {
        subject.send(FriendsState(subject.value, content: .loading(previous: subject.value.content)))
        switch await loadData() {
        case .success(let data):
            subject.send(FriendsState(subject.value, content: .loaded(data)))
        case .failure(let error):
            subject.send(FriendsState(subject.value, content: .failed(previous: subject.value.content, "error \(error)")))
        }
    }

    func addFriendViaQr() async {
        let addByQrModel = await AddFriendByQrModel(appRouter: appRouter)
        switch await addByQrModel.start() {
        case .success(let url):
            switch url {
            case .users(let users):
                switch users {
                case .show(let uid):
                    await showUser(uid: uid)
                }
            }
        case .failure(let reason):
            switch reason {
            case .alreadyRunning, .canceledManually:
                break
            case .internalError(let error):
                await appRouter.alert(
                    config: Alert.Config(
                        title: "unknown_error_hint".localized,
                        message: "\(error)",
                        actions: [
                            Alert.Action(
                                title: "alert_action_ok".localized
                            )
                        ]
                    )
                )
            }
        }
    }

    func searchForFriends() async {
        let model = await FriendsSearchModel(di: di, appRouter: appRouter)
        await model.setFriendsModel(self)
        await model.start()
    }

    private func loadData() async -> Result<FriendsState.Content, Error> {
        await friendListRepository.getFriends(set: [.friends, .incoming, .pending]).map { data in
            FriendsState.Content(
                upcomingRequests: data[.incoming] ?? [],
                pendingRequests: data[.pending] ?? [],
                friends: data[.friends] ?? []
            )
        }.mapError { $0 as Error }
    }

    func showUser(uid: User.ID) async {
        switch await usersRepository.getUsers(ids: [uid]) {
        case .success(let info):
            guard let user = info.first else {
                break
            }
            await showUser(user: user)
        case .failure(let error):
            switch error {
            case .noConnection(let error):
                await appRouter.alert(
                    config: Alert.Config(
                        title: "no_connection_hint".localized,
                        message: "\(error)",
                        actions: [
                            Alert.Action(
                                title: "alert_action_try_again".localized,
                                handler: { [weak self] _ in
                                    guard let self else { return }
                                    Task {
                                        await self.showUser(uid: uid)
                                    }
                                }
                            ),
                            Alert.Action(
                                title: "alert_action_ok".localized
                            )
                        ]
                    )
                )
            case .notAuthorized(let error):
                await appRouter.alert(
                    config: Alert.Config(
                        title: "alert_title_unauthorized".localized,
                        message: "\(error)",
                        actions: [
                            Alert.Action(
                                title: "alert_action_auth".localized,
                                handler: { [weak self] _ in
                                    guard let self else { return }
                                    Task {
                                        await self.mainModel?.logout()
                                    }
                                }
                            )
                        ]
                    )
                )
            case .other(let error):
                await appRouter.alert(
                    config: Alert.Config(
                        title: "unknown_error_hint".localized,
                        message: "\(error)",
                        actions: [
                            Alert.Action(
                                title: "alert_action_ok".localized
                            )
                        ]
                    )
                )
            }
        }
    }

    func showUser(user: User) async {
        let model = UserModel(di: di, user: user, appRouter: appRouter)
        if let mainModel {
            await model.setMainModel(mainModel)
        }
        await model.start()
    }
}
