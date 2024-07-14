import Combine
import Domain
import DI
internal import DesignSystem

actor FriendsModel {
    enum FlowResult {
        case loggedOut
        case canceled
    }
    let subject = CurrentValueSubject<FriendsState, Never>(FriendsState(content: .initial))

    private let appRouter: AppRouter
    private let friendListRepository: FriendsRepository
    private let usersRepository: UsersRepository
    private let di: ActiveSessionDIContainer
    private var subscriptions = Set<AnyCancellable>()

    init(di: ActiveSessionDIContainer, appRouter: AppRouter) async {
        self.di = di
        friendListRepository = di.friendListRepository()
        usersRepository = di.usersRepository()
        self.appRouter = appRouter
    }

    private var flowContinuation: CheckedContinuation<FlowResult, Never>?

    func performFlow() async -> FlowResult {
        if flowContinuation != nil {
            assertionFailure("friends flow is already running")
        }
        friendListRepository.friendsUpdated
            .sink { [weak self ] _ in
                Task { [weak self] in
                    guard let self else { return }
                    guard case .success(let data) = await loadData() else {
                        return
                    }
                    subject.send(FriendsState(subject.value, content: .loaded(data)))
                }
            }
            .store(in: &subscriptions)
        return await withCheckedContinuation { continuation in
            Task {
                flowContinuation = continuation
            }
        }
    }

    func refresh() async {
        let hudShown: Bool
        if case .initial = subject.value.content {
            hudShown = true
            await appRouter.showHud(graceTime: 0.5)
        } else {
            hudShown = false
        }
        subject.send(FriendsState(subject.value, content: .loading(previous: subject.value.content)))
        switch await loadData() {
        case .success(let data):
            if hudShown {
                await appRouter.hideHud()
            }
            subject.send(FriendsState(subject.value, content: .loaded(data)))
        case .failure(let error):
            if hudShown {
                await appRouter.hideHud()
            }
            switch error {
            case .noConnection:
                subject.send(
                    FriendsState(
                        subject.value,
                        content: .failed(previous: subject.value.content, FriendsState.Failure(
                            hint: "no_connection_hint".localized,
                            iconName: "network.slash"
                        ))
                    )
                )
            case .notAuthorized(let error):
                await showNotAuthorizedAlert(error: error)
            case .other:
                subject.send(
                    FriendsState(
                        subject.value,
                        content: .failed(previous: subject.value.content, FriendsState.Failure(
                            hint: "unknown_error_hint".localized,
                            iconName: "exclamationmark.triangle"
                        ))
                    )
                )
            }
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

    private func loadData() async -> Result<FriendsState.Content, RepositoryError> {
        await friendListRepository.getFriends(set: [.friends, .incoming, .pending]).map { data in
            FriendsState.Content(
                upcomingRequests: data[.incoming] ?? [],
                pendingRequests: data[.pending] ?? [],
                friends: data[.friends] ?? []
            )
        }
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
                            Alert.Action(title: "alert_action_try_again".localized) { [weak self] _ in
                                await self?.showUser(uid: uid)
                            },
                            Alert.Action(
                                title: "alert_action_ok".localized
                            )
                        ]
                    )
                )
            case .notAuthorized(let error):
                await showNotAuthorizedAlert(error: error)
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

    private func showNotAuthorizedAlert(error: Error) async {
        await appRouter.alert(
            config: Alert.Config(
                title: "alert_title_unauthorized".localized,
                message: "\(error)",
                actions: [
                    Alert.Action(title: "alert_action_auth".localized) { [weak self] _ in
                        await self?.handle(flowResult: .loggedOut)
                    }
                ]
            )
        )
    }

    func showUser(user: User) async {
        let model = UserModel(di: di, user: user, appRouter: appRouter)
        Task.detached {
            switch await model.performFlow() {
            case .loggedOut:
                await self.handle(flowResult: .loggedOut)
            case .canceled:
                break
            }
        }
    }
}

extension FriendsModel: CancelableFlow {
    func handleCancel() async {
        await handle(flowResult: .canceled)
    }

    private func handle(flowResult: FlowResult) async {
        guard let flowContinuation = flowContinuation else {
            return assertionFailure("friends flow: got logout after flow is finished")
        }
        subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        subscriptions.removeAll()
        self.flowContinuation = nil
        flowContinuation.resume(returning: flowResult)
    }
}

extension FriendsModel: UrlResolver {
    func canResolve(url: InternalUrl) async -> Bool {
        guard case .users(let users) = url, case .show = users else {
            return false
        }
        return true
    }
    
    func resolve(url: InternalUrl) async {
        guard case .users(let users) = url, case .show(let id) = users else {
            return
        }
        await showUser(uid: id)
    }
}
