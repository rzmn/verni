import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD
internal import UserPreviewFlow

public actor FriendsFlow {
    private var _presenter: FriendsPresenter?
    private func presenter() async -> FriendsPresenter {
        guard let _presenter else {
            let presenter = await FriendsPresenter(router: router, actions: await makeActions())
            _presenter = presenter
            return presenter
        }
        return _presenter
    }
    private let viewModel: FriendsViewModel
    private let di: ActiveSessionDIContainer
    private let router: AppRouter
    private let usersRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository
    private let friendListRepository: FriendsRepository
    private var subscriptions = Set<AnyCancellable>()
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di

        let offlineFriends = di.friendsOfflineRepository()
        let offlineSpendings = di.spendingsOfflineRepository()

        async let asyncFriends = offlineFriends.getFriends(set: .all)
        async let asyncSpendings = offlineSpendings.getSpendingCounterparties()

        let cached = await (friends: asyncFriends, spendings: asyncSpendings)

        if let friends = cached.friends, let spendings = cached.spendings {
            viewModel = await FriendsViewModel(friends: friends, spendings: spendings)
        } else {
            viewModel = await FriendsViewModel()
        }
        spendingsRepository = di.spendingsRepository
        usersRepository = di.usersRepository
        friendListRepository = di.friendListRepository
    }

    public func setActive(_ active: Bool) async {
        let wasActive = !subscriptions.isEmpty
        guard active != wasActive else {
            return
        }
        if active {
            await friendListRepository
                .friendsUpdated(ofKind: .all)
                .sink(receiveValue: { friends in
                    Task.detached {
                        await self.viewModel.reload(friends: friends)
                    }
                })
                .store(in: &subscriptions)
        } else {
            subscriptions.removeAll()
        }
    }
}

// MARK: - Flow

extension FriendsFlow: TabEmbedFlow {
    public typealias FlowResult = Void
    public func perform() async -> FlowResult {}

    @MainActor public func viewController() async -> Routable {
        await presenter().tabViewController
    }
}

// MARK: - User Actions

extension FriendsFlow {
    private func makeActions() async -> FriendsViewActions {
        await FriendsViewActions(state: viewModel.$state) { action in
            Task.detached { [weak self] in
                guard let self else { return }
                switch action {
                case .onAddViaQrTap:
                    await addViaQr()
                case .onUserSelected(let user):
                    await openPreview(user: user)
                case .onViewAppeared:
                    await refresh()
                case .onPulledToRefresh:
                    await refresh()
                }
            }
        }
    }
}

// MARK: - Url Resolver

extension FriendsFlow: UrlResolver {
    public func resolve(url: AppUrl) async {
        guard case .users(let usersAction) = url else {
            return
        }
        guard case .show(let uid) = usersAction else {
            return
        }
        await presenter().presentLoading()
        switch await usersRepository.getUsers(ids: [uid]) {
        case .success(let users):
            await presenter().dismissLoading()
            guard let user = users.first else {
                return
            }
            let flow = await UserPreviewFlow(di: di, router: router, user: user)
            _ = await flow.perform()
        case .failure(let error):
            await presenter().presentGeneralError(error)
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

// MARK: - Private

extension FriendsFlow {
    private func addViaQr() async {
        let flow = await AddFriendByQrFlow(router: router)
        switch await flow.perform() {
        case .success(let url):
            await router.open(url: url)
        case .failure:
            break
        }
    }

    private func openPreview(user: User) async {
        let flow = await UserPreviewFlow(di: di, router: router, user: user)
        _ = await flow.perform()
    }

    private func refresh() async {
        let state = await viewModel.state
        let hudShown: Bool
        if case .initial = state.content {
            hudShown = true
            await presenter().presentLoading()
        } else {
            hudShown = false
        }
        Task { @MainActor [unowned self] in
            self.viewModel.content = .loading(previous: state.content)
        }

        async let asyncFriends = friendListRepository.refreshFriends(ofKind: .all)
        async let asyncSpendings = spendingsRepository.refreshSpendingCounterparties()

        let result = await (asyncFriends, asyncSpendings)

        Task { @MainActor [unowned self] in
            if hudShown {
                await presenter().dismissLoading()
            }
            switch result {
            case (.success(let friends), .success(let spendings)):
                viewModel.reload(friends: friends, spendings: spendings)
            case (_, .failure(let error)), (.failure(let error), _):
                viewModel.reload(error: error)
            }
        }
    }
}
