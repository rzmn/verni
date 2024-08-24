import Combine
import AppBase
import DI
import Domain

public actor UserPreviewFlow {
    @MainActor var subject: Published<UserPreviewState>.Publisher {
        viewModel.$state
    }

    private let viewModel: UserPreviewViewModel
    private let router: AppRouter
    private let friendStatusInteractions: FriendInteractionsUseCase
    private let spendingsRepository: SpendingsRepository
    private lazy var presenter = UserPreviewFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter, user: User) async {
        let spendingsOfflineRepository = di.spendingsOfflineRepository()
        viewModel = await UserPreviewViewModel(
            hostId: di.userId,
            counterparty: user,
            spendings: await spendingsOfflineRepository.getSpendingsHistory(
                counterparty: user.id
            )
        )
        self.router = router
        spendingsRepository = di.spendingsRepository()
        friendStatusInteractions = di.friendInterationsUseCase()
    }
}

extension UserPreviewFlow: Flow {
    public enum TerminationEvent: Error {
        case canceledManually
    }

    public func perform() async -> TerminationEvent {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached { @MainActor in
                await self.presenter.openUserPreview { [weak self] in
                    guard let self else { return }
                    await handle(result: .canceledManually)
                }
            }
        }
    }

    private func handle(result: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        if case .canceledManually = result {
        } else {
            await presenter.closeUserPreview()
        }
        flowContinuation.resume(returning: result)
    }
}

extension UserPreviewFlow {
    @MainActor func refresh() {
        Task.detached {
            await self.doRefresh()
        }
    }

    private func doRefresh() async {
        let state = await viewModel.state
        let shouldShowHud: Bool
        if case .initial = state.spenginds {
            shouldShowHud = true
        } else {
            shouldShowHud = false
        }
        if shouldShowHud {
            await presenter.presentLoading()
        }
        let result = await spendingsRepository.refreshSpendingsHistory(counterparty: state.user.id)
        Task { @MainActor [unowned self] in
            if shouldShowHud {
                await presenter.dismissLoading()
            }
            switch result {
            case .success(let spendings):
                viewModel.spendings = .loaded(spendings)
            case .failure(let error):
                switch error {
                case .noSuchCounterparty:
                    viewModel.spendings = .failed(
                        previous: viewModel.spendings,
                        UserPreviewState.Failure(
                            hint: "alert_action_no_such_user".localized,
                            iconName: "network.slash"
                        )
                    )
                case .other(let error):
                    switch error {
                    case .noConnection:
                        viewModel.spendings = .failed(
                            previous: viewModel.spendings,
                            UserPreviewState.Failure(
                                hint: "no_connection_hint".localized,
                                iconName: "network.slash"
                            )
                        )
                    case .notAuthorized:
                        viewModel.spendings = .failed(
                            previous: viewModel.spendings,
                            UserPreviewState.Failure(
                                hint: "alert_title_unauthorized".localized,
                                iconName: "network.slash"
                            )
                        )
                    case .other:
                        viewModel.spendings = .failed(
                            previous: viewModel.spendings,
                            UserPreviewState.Failure(
                                hint: "unknown_error_hint".localized,
                                iconName: "exclamationmark.triangle"
                            )
                        )
                    }
                }
            }
        }
    }

    @MainActor func sendRequest() {
        Task.detached {
            await self.doSendRequest()
        }
    }

    private func doSendRequest() async {
        let state = await viewModel.state
        switch state.user.status {
        case .friend, .incoming, .me, .outgoing:
            return
        case .no:
            break
        }
        switch await friendStatusInteractions.sendFriendRequest(to: state.user.id) {
        case .success:
            Task { @MainActor in
                self.viewModel.friendStatus = .outgoing
            }
        case .failure(let reason):
            switch reason {
            case .alreadySent:
                await presenter.present(hint: "alert_action_already_sent".localized)
            case .haveIncoming:
                await presenter.present(hint: "alert_action_have_incoming".localized)
            case .alreadyFriends:
                await presenter.present(hint: "alert_action_already_friends".localized)
            case .noSuchUser:
                await presenter.presentNoSuchUser()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    @MainActor func acceptRequest() {
        Task.detached {
            await self.doAcceptRequest()
        }
    }

    private func doAcceptRequest() async {
        let state = await viewModel.state
        switch state.user.status {
        case .friend, .no, .me, .outgoing:
            return
        case .incoming:
            break
        }
        switch await friendStatusInteractions.acceptFriendRequest(from: state.user.id) {
        case .success:
            Task { @MainActor in
                self.viewModel.friendStatus = .friend
            }
        case .failure(let error):
            switch error {
            case .noSuchRequest:
                await presenter.present(hint: "alert_action_no_such_request".localized)
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    @MainActor func rejectRequest() {
        Task.detached {
            await self.doRejectRequest()
        }
    }

    private func doRejectRequest() async {
        let state = await viewModel.state
        switch state.user.status {
        case .friend, .no, .me, .outgoing:
            return
        case .incoming:
            break
        }
        switch await friendStatusInteractions.rejectFriendRequest(from: state.user.id) {
        case .success:
            Task { @MainActor in
                self.viewModel.friendStatus = .no
            }
        case .failure(let error):
            switch error {
            case .noSuchRequest:
                await presenter.present(hint: "alert_action_no_such_request".localized)
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    @MainActor func rollbackRequest() {
        Task.detached {
            await self.doRollbackRequest()
        }
    }

    private func doRollbackRequest() async {
        let state = await viewModel.state
        switch state.user.status {
        case .friend, .no, .me, .incoming:
            return
        case .outgoing:
            break
        }
        switch await friendStatusInteractions.rollbackFriendRequest(to: state.user.id) {
        case .success:
            Task { @MainActor in
                self.viewModel.friendStatus = .no
            }
        case .failure(let error):
            switch error {
            case .noSuchRequest:
                await presenter.presentNoSuchUser()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    @MainActor func unfriend() {
        Task.detached {
            await self.doUnfriend()
        }
    }

    private func doUnfriend() async {
        let state = await viewModel.state
        switch state.user.status {
        case .incoming, .no, .me, .outgoing:
            return
        case .friend:
            break
        }
        switch await friendStatusInteractions.unfriend(user: state.user.id) {
        case .success:
            Task { @MainActor in
                self.viewModel.friendStatus = .no
            }
        case .failure(let error):
            switch error {
            case .notAFriend:
                await presenter.present(hint: "alert_action_not_a_friend".localized)
            case .noSuchUser:
                await presenter.present(hint: "alert_action_no_such_user".localized)
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }
}
