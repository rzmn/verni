import Combine
import AppBase
import DI
import Domain
import AsyncExtensions

public actor UserPreviewFlow {
    private lazy var presenter = AsyncLazyObject {
        UserPreviewPresenter(
            router: self.router,
            actions: await MainActor.run {
                self.makeActions()
            }
        )
    }
    private let viewModel: UserPreviewViewModel
    private let router: AppRouter
    private let friendStatusInteractions: FriendInteractionsUseCase
    private let spendingsRepository: SpendingsRepository
    private let friendsRepository: FriendsRepository
    private var flowContinuation: Continuation?
    private var friendsSubscription: (any CancellableEventSource)?

    public init(di: ActiveSessionDIContainer, router: AppRouter, user: User) async {
        let spendingsOfflineRepository = di.spendingsOfflineRepository
        viewModel = await UserPreviewViewModel(
            hostId: di.userId,
            counterparty: user,
            spendings: await spendingsOfflineRepository.getSpendingsHistory(
                counterparty: user.id
            )
        )
        self.router = router
        spendingsRepository = di.spendingsRepository
        friendsRepository = di.friendListRepository
        friendStatusInteractions = di.friendInterationsUseCase()
    }
}

// MARK: - Flow

extension UserPreviewFlow: Flow {
    public enum TerminationEvent: Error {
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
        friendsSubscription = await friendsRepository.friendsUpdated(ofKind: .all).subscribe { [weak self] friends in
            guard let self else { return }
            Task {
                self.friendsUpdated(friends: friends)
            }
        }
        await presenter.value.openUserPreview { [weak self] in
            guard let self else { return }
            await handle(result: .canceledManually)
        }
    }

    private func handle(result: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        if case .canceledManually = result {
        } else {
            await presenter.value.closeUserPreview()
        }
        flowContinuation.resume(returning: result)
    }
}

// MARK: - User Actions

extension UserPreviewFlow {
    @MainActor private func makeActions() -> UserPreviewViewActions {
        UserPreviewViewActions(state: viewModel.$state) { action in
            Task.detached { [weak self] in
                guard let self else { return }
                switch action {
                case .onViewAppeared:
                    await refresh()
                case .onSendFriendRequestTap:
                    await sendFriendRequest()
                case .onAcceptFriendRequestTap:
                    await acceptFriendRequest()
                case .onRejectFriendRequestTap:
                    await rejectFriendRequest()
                case .onRollbackFriendRequestTap:
                    await rollbackFriendRequest()
                case .onUnfriendTap:
                    await unfriend()
                }
            }
        }
    }
}

// MARK: - Private

extension UserPreviewFlow {
    private func refresh() async {
        let state = await viewModel.state
        let shouldShowHud: Bool
        if case .initial = state.spenginds {
            shouldShowHud = true
        } else {
            shouldShowHud = false
        }
        if shouldShowHud {
            await presenter.value.presentLoading()
        }
        do {
            let spendings = try await spendingsRepository.refreshSpendingsHistory(counterparty: state.user.id)
            if shouldShowHud {
                await presenter.value.dismissLoading()
            }
            await viewModel.reload(spendings: spendings)
        } catch {
            if shouldShowHud {
                await presenter.value.dismissLoading()
            }
            await viewModel.reload(error: error)
        }
    }

    private nonisolated func friendsUpdated(friends: [FriendshipKind: [User]]) {
        Task.detached {
            await self.updateFriends(friends: friends)
        }
    }

    private func updateFriends(friends: [FriendshipKind: [User]]) async {
        let counterpartyId = await viewModel.state.user.id
        let updated = friends.values
            .flatMap { $0 }
            .first { $0.id == counterpartyId }
        guard let updated else {
            return
        }
        await viewModel.reload(user: updated)
    }

    private func sendFriendRequest() async {
        let state = await viewModel.state
        switch state.user.status {
        case .friend, .incoming, .currentUser, .outgoing:
            return
        case .notAFriend:
            break
        }
        do {
            try await friendStatusInteractions.sendFriendRequest(to: state.user.id)
            await presenter.value.successHaptic()
            await presenter.value.presentSuccess()
        } catch {
            switch error {
            case .alreadySent:
                await presenter.value.present(hint: "alert_action_already_sent".localized)
            case .haveIncoming:
                await presenter.value.present(hint: "alert_action_have_incoming".localized)
            case .alreadyFriends:
                await presenter.value.present(hint: "alert_action_already_friends".localized)
            case .noSuchUser:
                await presenter.value.presentNoSuchUser()
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
    }

    private func acceptFriendRequest() async {
        let state = await viewModel.state
        switch state.user.status {
        case .friend, .notAFriend, .currentUser, .outgoing:
            return
        case .incoming:
            break
        }
        do {
            try await friendStatusInteractions.acceptFriendRequest(from: state.user.id)
            await presenter.value.successHaptic()
            await presenter.value.presentSuccess()
        } catch {
            switch error {
            case .noSuchRequest:
                await presenter.value.present(hint: "alert_action_no_such_request".localized)
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
    }

    private func rejectFriendRequest() async {
        let state = await viewModel.state
        switch state.user.status {
        case .friend, .notAFriend, .currentUser, .outgoing:
            return
        case .incoming:
            break
        }
        do {
            try await friendStatusInteractions.rejectFriendRequest(from: state.user.id)
            await presenter.value.successHaptic()
            await presenter.value.presentSuccess()
        } catch {
            switch error {
            case .noSuchRequest:
                await presenter.value.present(hint: "alert_action_no_such_request".localized)
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
    }

    private func rollbackFriendRequest() async {
        let state = await viewModel.state
        switch state.user.status {
        case .friend, .notAFriend, .currentUser, .incoming:
            return
        case .outgoing:
            break
        }
        do {
            try await friendStatusInteractions.rollbackFriendRequest(to: state.user.id)
            await presenter.value.successHaptic()
            await presenter.value.presentSuccess()
        } catch {
            switch error {
            case .noSuchRequest:
                await presenter.value.presentNoSuchUser()
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
    }

    private func unfriend() async {
        let state = await viewModel.state
        switch state.user.status {
        case .incoming, .notAFriend, .currentUser, .outgoing:
            return
        case .friend:
            break
        }
        do {
            try await friendStatusInteractions.unfriend(user: state.user.id)
            await presenter.value.successHaptic()
            await presenter.value.presentSuccess()
        } catch {
            switch error {
            case .notAFriend:
                await presenter.value.present(hint: "alert_action_not_a_friend".localized)
            case .noSuchUser:
                await presenter.value.present(hint: "alert_action_no_such_user".localized)
            case .other(let error):
                await presenter.value.presentGeneralError(error)
            }
        }
    }
}
