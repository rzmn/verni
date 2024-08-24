import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD

public actor PickCounterpartyFlow {
    @MainActor var subject: Published<PickCounterpartyState>.Publisher {
        viewModel.$state
    }

    private lazy var presenter = PickCounterpartyFlowPresenter(router: router, flow: self)
    private let viewModel: PickCounterpartyViewModel
    private let friendsRepository: FriendsRepository
    private let router: AppRouter
    private var subscriptions = Set<AnyCancellable>()
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        friendsRepository = di.friendListRepository()
        viewModel = await PickCounterpartyViewModel(
            friends: await di
                .friendsOfflineRepository()
                .getFriends(set: .all)
        )
    }
}

// MARK: - Flow

extension PickCounterpartyFlow: Flow {
    public enum TerminationEvent {
        case picked(User)
        case canceledManually
    }

    public func perform() async -> TerminationEvent {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached {
                await self.startFlow()
            }
        }
    }

    private func startFlow() async {
        await self.presenter.present()
        await friendsRepository
            .friendsUpdated(ofKind: .all)
            .sink { friends in
                Task.detached {
                    await self.reload(result: .success(friends))
                }
            }
            .store(in: &subscriptions)
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        subscriptions.removeAll()
        self.flowContinuation = nil
        if case .canceledManually = event {
        } else {
            await presenter.dismiss()
        }
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension PickCounterpartyFlow {
    @MainActor func cancel() {
        Task.detached {
            await self.presenter.dismiss()
        }
    }

    @MainActor func pick(counterparty: User) {
        Task.detached {
            await self.handle(event: .picked(counterparty))
        }
    }

    @MainActor func appeared() {
        Task.detached {
            await self.refresh(manually: false)
        }
    }
}

// MARK: - Private

extension PickCounterpartyFlow {
    private func refresh(manually: Bool) async {
        let state = await viewModel.state
        if case .initial = state.content {
            await presenter.presentLoading()
        }
        Task { @MainActor [unowned self] in
            viewModel.content = .loading(previous: state.content)
        }
        reload(result: await friendsRepository.refreshFriends(ofKind: .all))
    }

    private func reload(result: Result<[FriendshipKind: [User]], GeneralError>) {
        Task { @MainActor [unowned self] in
            await presenter.dismissLoading()
            switch result {
            case .success(let friends):
                viewModel.reload(friends: friends)
            case .failure(let error):
                viewModel.reload(error: error)
            }
        }
    }
}
