import UIKit
import Domain
import DI
import AppBase
import AsyncExtensions
internal import DesignSystem
internal import ProgressHUD
internal import Base

public actor PickCounterpartyFlow {
    private var _presenter: PickCounterpartyPresenter?
    @MainActor private func presenter() async -> PickCounterpartyPresenter {
        guard let presenter = await _presenter else {
            let presenter = PickCounterpartyPresenter(router: router, actions: await makeActions())
            await mutate { s in
                s._presenter = presenter
            }
            return presenter
        }
        return presenter
    }
    private let viewModel: PickCounterpartyViewModel
    private let friendsRepository: FriendsRepository
    private let router: AppRouter
    private var friendsSubscription: (any CancellableEventSource)?
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        friendsRepository = di.friendListRepository
        viewModel = await PickCounterpartyViewModel(
            friends: await di
                .friendsOfflineRepository
                .getFriends(set: .all)
        )
    }
}

// MARK: - Flow

extension PickCounterpartyFlow: Flow {
    public enum TerminationEvent: Sendable {
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
        await self.presenter().present()
        friendsSubscription = await friendsRepository.friendsUpdated(ofKind: .all).subscribe { [weak self] friends in
            guard let self else { return }
            Task {
                self.friendsUpdated(friends: friends)
            }
        }
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        await friendsSubscription?.cancel()
        friendsSubscription = nil
        self.flowContinuation = nil
        if case .canceledManually = event {
        } else {
            await presenter().dismiss()
        }
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension PickCounterpartyFlow {
    @MainActor private func makeActions() async -> PickCounterpartyViewActions {
        PickCounterpartyViewActions(state: viewModel.$state) { [weak self] userAction in
            guard let self else { return }
            switch userAction {
            case .onCancelTap:
                Task.detached {
                    await self.presenter().dismiss()
                }
            case .onPickounterpartyTap(let user):
                Task.detached {
                    await self.handle(event: .picked(user))
                }
            case .onViewAppeared:
                let state = self.viewModel.state
                let firstCall: Bool
                if case .initial = state.content {
                    firstCall = true
                } else {
                    firstCall = false
                }
                self.viewModel.markLoading()
                Task.detached {
                    await self.refresh(firstCall: firstCall, manually: false)
                }
            }
        }
    }
}

// MARK: - Private

extension PickCounterpartyFlow {
    private func refresh(firstCall: Bool, manually: Bool) async {
        if firstCall {
            await presenter().presentLoading()
        }
        do {
            await updateFriends(friends: try await friendsRepository.refreshFriends(ofKind: .all))
        } catch {
            await presenter().dismissLoading()
            await viewModel.failed(error: error)
        }
    }

    private nonisolated func friendsUpdated(friends: [FriendshipKind: [User]]) {
        Task.detached {
            await self.updateFriends(friends: friends)
        }
    }

    private func updateFriends(friends: [FriendshipKind: [User]]) async {
        await presenter().dismissLoading()
        await viewModel.loaded(friends: friends)
    }
}
