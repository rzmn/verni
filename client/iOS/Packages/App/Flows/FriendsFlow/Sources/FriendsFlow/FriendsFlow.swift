import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD
internal import UserPreviewFlow

public actor FriendsFlow {
    @MainActor var subject: Published<FriendsState>.Publisher {
        viewModel.$state
    }

    private let viewModel: FriendsViewModel
    private let di: ActiveSessionDIContainer
    private let router: AppRouter
    private let profileRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository
    private let friendListRepository: FriendsRepository
    private lazy var presenter = FriendsFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di

        let offlineFriends = di.friendsOfflineRepository()
        let offlineSpendings = di.spendingsOfflineRepository()

        async let asyncFriends = offlineFriends.getFriends(set: Set(FriendshipKind.allCases))
        async let asyncSpendings = offlineSpendings.getSpendingCounterparties()

        let cached = await (friends: asyncFriends, spendings: asyncSpendings)

        if let friends = cached.friends, let spendings = cached.spendings {
            viewModel = await FriendsViewModel(friends: friends, spendings: spendings)
        } else {
            viewModel = await FriendsViewModel()
        }

        spendingsRepository = di.spendingsRepository()
        profileRepository = di.usersRepository()
        friendListRepository = di.friendListRepository()
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
        let flow = await UserPreviewFlow(di: di, router: router, user: user)
        _ = await flow.perform()
    }

    @MainActor
    func refresh() {
        Task.detached {
            await self.doRefresh()
        }
    }

    private func doRefresh() async {
        let state = await viewModel.state
        let hudShown: Bool
        if case .initial = state.content {
            hudShown = true
            await presenter.presentLoading()
        } else {
            hudShown = false
        }
        Task { @MainActor [unowned self] in
            self.viewModel.content = .loading(previous: state.content)
        }

        async let asyncFriends = friendListRepository.getFriends(set: Set(FriendshipKind.allCases))
        async let asyncSpendings = spendingsRepository.getSpendingCounterparties()

        let result = await (asyncFriends, asyncSpendings)

        Task { @MainActor [unowned self] in
            if hudShown {
                await presenter.dismissLoading()
            }
            switch result {
            case (.success(let friends), .success(let spendings)):
                viewModel.reload(friends: friends, spendings: spendings)
            case (_, .failure(let error)), (.failure(let error), _):
                switch error {
                case .noConnection:
                    viewModel.content = .failed(
                        previous: viewModel.content,
                        FriendsState.Failure(
                            hint: "no_connection_hint".localized,
                            iconName: "network.slash"
                        )
                    )
                case .notAuthorized:
                    viewModel.content = .failed(
                        previous: viewModel.content,
                        FriendsState.Failure(
                            hint: "alert_title_unauthorized".localized,
                            iconName: "network.slash"
                        )
                    )
                case .other:
                    viewModel.content = .failed(
                        previous: viewModel.content,
                        FriendsState.Failure(
                            hint: "unknown_error_hint".localized,
                            iconName: "exclamationmark.triangle"
                        )
                    )
                }
            }
        }
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
            let flow = await UserPreviewFlow(di: di, router: router, user: user)
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
