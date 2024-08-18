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
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        friendsRepository = di.friendListRepository()
        viewModel = await PickCounterpartyViewModel(
            friends: await di
                .friendsOfflineRepository()
                .getFriends(set: Set(FriendshipKind.allCases))
        )
    }
}

extension PickCounterpartyFlow: Flow {
    public enum TerminationEvent {
        case picked(User)
        case canceledManually
    }

    public func perform() async -> TerminationEvent {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached { @MainActor in
                await self.presenter.present()
            }
        }
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        if case .canceledManually = event {
        } else {
            await presenter.dismiss()
        }
        flowContinuation.resume(returning: event)
    }
}

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

    @MainActor func refresh() {
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
            viewModel.content = .loading(previous: state.content)
        }
        let result = await friendsRepository.getFriends(set: Set(FriendshipKind.allCases))
        Task { @MainActor [unowned self] in
            switch result {
            case .success(let friends):
                await presenter.dismissLoading()
                viewModel.reload(friends: friends)
            case .failure(let error):
                if hudShown {
                    await presenter.dismissLoading()
                }
                switch error {
                case .noConnection:
                    viewModel.content = .failed(
                        previous: state.content,
                        PickCounterpartyState.Failure(
                            hint: "no_connection_hint".localized,
                            iconName: "network.slash"
                        )
                    )
                case .notAuthorized:
                    viewModel.content = .failed(
                        previous: state.content,
                        PickCounterpartyState.Failure(
                            hint: "alert_title_unauthorized".localized,
                            iconName: "network.slash"
                        )
                    )
                case .other:
                    viewModel.content = .failed(
                        previous: state.content,
                        PickCounterpartyState.Failure(
                            hint: "unknown_error_hint".localized,
                            iconName: "exclamationmark.triangle"
                        )
                    )
                }
            }
        }
    }
}
