import Combine
import AppBase
import DI
import Domain

private extension UserPreviewState {
    func withFriendStatus(_ status: User.FriendStatus) -> UserPreviewState {
        UserPreviewState(
            user: User(
                id: user.id,
                status: status,
                displayName: user.displayName,
                avatar: user.avatar
            )
        )
    }
}

actor UserPreviewFlow {
    let subject: CurrentValueSubject<UserPreviewState, Never>
    private let router: AppRouter
    private let useCase: FriendInteractionsUseCase
    private lazy var presenter = UserPreviewFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    init(di: ActiveSessionDIContainer, router: AppRouter, user: User) {
        subject = CurrentValueSubject(UserPreviewState(user: user))
        self.router = router
        useCase = di.friendInterationsUseCase()
    }
}

extension UserPreviewFlow: Flow {
    enum TerminationEvent: Error {
        case canceledManually
    }

    func perform() async -> TerminationEvent {
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
    func sendRequest() async {
        let state = subject.value
        switch state.user.status {
        case .friend, .incoming, .me, .outgoing:
            return
        case .no:
            break
        }
        switch await useCase.sendFriendRequest(to: state.user.id) {
        case .success:
            subject.send(state.withFriendStatus(.outgoing))
        case .failure(let reason):
            switch reason {
            case .alreadySent:
                await presenter.present(hint: "alert_action_already_sent".localized)
            case .haveIncoming:
                await presenter.present(hint: "alert_action_have_incoming".localized)
            case .alreadyFriends:
                await presenter.present(hint: "alert_action_already_friends".localized)
            case .noSuchUser:
                await presenter.present(hint: "alert_action_no_such_user".localized)
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    func acceptRequest() async {
        let state = subject.value
        switch state.user.status {
        case .friend, .no, .me, .outgoing:
            return
        case .incoming:
            break
        }
        switch await useCase.acceptFriendRequest(from: state.user.id) {
        case .success:
            subject.send(state.withFriendStatus(.friend))
        case .failure(let error):
            switch error {
            case .noSuchRequest:
                await presenter.present(hint: "alert_action_no_such_request".localized)
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    func rejectRequest() async {
        let state = subject.value
        switch state.user.status {
        case .friend, .no, .me, .outgoing:
            return
        case .incoming:
            break
        }
        switch await useCase.rejectFriendRequest(from: state.user.id) {
        case .success:
            subject.send(state.withFriendStatus(.no))
        case .failure(let error):
            switch error {
            case .noSuchRequest:
                await presenter.present(hint: "alert_action_no_such_request".localized)
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    func rollbackRequest() async {
        let state = subject.value
        switch state.user.status {
        case .friend, .no, .me, .incoming:
            return
        case .outgoing:
            break
        }
        switch await useCase.rollbackFriendRequest(to: state.user.id) {
        case .success:
            subject.send(state.withFriendStatus(.no))
        case .failure(let error):
            switch error {
            case .noSuchRequest:
                await presenter.present(hint: "alert_action_no_such_request".localized)
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    func unfriend() async {
        let state = subject.value
        switch state.user.status {
        case .incoming, .no, .me, .outgoing:
            return
        case .friend:
            break
        }
        switch await useCase.unfriend(user: state.user.id) {
        case .success:
            subject.send(state.withFriendStatus(.no))
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
