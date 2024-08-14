import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD

public actor FriendsFlow {
    @MainActor let subject = CurrentValueSubject<FriendsState, Never>(.initial)

    private let di: ActiveSessionDIContainer
    private let router: AppRouter
    private let profileRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository
    private let spendingsOfflineRepository: SpendingsOfflineRepository
    private let friendsOfflineRepository: FriendsOfflineRepository
    private let friendListRepository: FriendsRepository
    private lazy var presenter = FriendsFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di
        spendingsRepository = di.spendingsRepository()
        profileRepository = di.usersRepository()
        friendListRepository = di.friendListRepository()
        friendsOfflineRepository = di.friendsOfflineRepository()
        spendingsOfflineRepository = di.spendingsOfflineRepository()
    }

    func addViaQr() async {
        let flow = await AddFriendByQrFlow(router: router)
        switch await flow.perform() {
        case .success(let url):
            await router.open(url: url)
        case .failure:
            break
        }
    }

    func openPreview(user: User) async {
        let flow = UserPreviewFlow(di: di, router: router, user: user)
        _ = await flow.perform()
    }

    @MainActor
    func refresh() {
        let currentState = subject.value.content
        subject.send(FriendsState(subject.value, content: .loading(previous: currentState)))
        if case .initial = currentState {
            Task.detached {
                await self.loadFirstTime()
            }
        } else {
            Task.detached {
                await self.doRefresh()
            }
        }
    }

    private func loadFirstTime() async {
        async let asyncFriends = friendsOfflineRepository.getFriends(set: Set(FriendshipKind.allCases))
        async let asyncSpendings = spendingsOfflineRepository.getSpendingCounterparties()

        let cached = await (friends: asyncFriends, spendings: asyncSpendings)

        guard let friends = cached.friends, let spendings = cached.spendings else {
            return await doRefresh()
        }
        subject.send(FriendsState(content: .loaded(build(friends: friends, spendings: spendings))))
        await doRefresh()
    }

    private func doRefresh() async {
        let hudShown: Bool
        if case .initial = subject.value.content {
            hudShown = true
            await presenter.presentLoading()
        } else {
            hudShown = false
        }
        subject.send(FriendsState(subject.value, content: .loading(previous: subject.value.content)))
        switch await loadData() {
        case .success(let data):
            await presenter.dismissLoading()
            subject.send(FriendsState(subject.value, content: .loaded(data)))
        case .failure(let error):
            if hudShown {
                await presenter.dismissLoading()
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
            case .notAuthorized:
                subject.send(
                    FriendsState(
                        subject.value,
                        content: .failed(previous: subject.value.content, FriendsState.Failure(
                            hint: "alert_title_unauthorized".localized,
                            iconName: "network.slash"
                        ))
                    )
                )
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

    private func loadData() async -> Result<FriendsState.Content, GeneralError> {
        async let asyncFriends = friendListRepository.getFriends(set: Set(FriendshipKind.allCases))
        async let asyncSpendings = spendingsRepository.getSpendingCounterparties()

        let data = await (asyncFriends, asyncSpendings)

        switch data {
        case (.success(let friends), .success(let spendings)):
            return .success(build(friends: friends, spendings: spendings))
        case (_, .failure(let error)), (.failure(let error), _):
            return .failure(error)
        }
    }

    private func build(friends: [FriendshipKind: [User]], spendings: [SpendingsPreview]) -> FriendsState.Content {
        let userToSpendings = spendings.reduce(into: [:]) { dict, preview in
            dict[preview.counterparty] = preview.balance
        }
        let buildSection = { (sectionIdentifier: FriendshipKind) -> FriendsState.Section? in
            guard let users = friends[sectionIdentifier] else {
                return nil
            }
            return FriendsState.Section(
                id: sectionIdentifier,
                items: users.map { user in
                    FriendsState.Item(
                        user: user,
                        balance: userToSpendings[user.id] ?? [:]
                    )
                }
            )
        }
        return FriendsState.Content(
            sections: FriendsState.Section.order.compactMap(buildSection)
        )
    }
}

extension FriendsFlow: TabEmbedFlow {
    public typealias FlowResult = Void
    public func perform() async -> FlowResult {}

    @MainActor public func viewController() async -> Routable {
        await presenter.tabViewController
    }
}

extension FriendsFlow: UrlResolver {

    public func resolve(url: AppUrl) async {
        guard case .users(let usersAction) = url else {
            return
        }
        guard case .show(let uid) = usersAction else {
            return
        }
        await presenter.presentLoading()
        switch await profileRepository.getUsers(ids: [uid]) {
        case .success(let users):
            await presenter.dismissLoading()
            guard let user = users.first else {
                return
            }
            let flow = UserPreviewFlow(di: di, router: router, user: user)
            _ = await flow.perform()
        case .failure(let error):
            await presenter.presentGeneralError(error)
        }
    }

    public func canResolve(url: AppUrl) async -> Bool {
        guard case .users(let usersAction) = url else {
            return false
        }
        guard case .show = usersAction else {
            return false
        }
        return true
    }
}
