import Domain
import Combine
import DI
internal import DesignSystem

private extension UserState {
    func withFriendStatus(_ status: User.FriendStatus) -> UserState {
        UserState(self, user: User(id: user.id, status: status))
    }
}

actor UserModel {
    enum FlowResult {
        case loggedOut
        case canceled
    }

    let subject: CurrentValueSubject<UserState, Never>
    private let useCase: FriendInteractionsUseCase
    private let router: AppRouter
    private lazy var presenter = UserPresenter(appRouter: router, model: self)

    init(di: ActiveSessionDIContainer, user: User, appRouter: AppRouter) {
        useCase = di.friendInterationsUseCase()
        subject = CurrentValueSubject(UserState(user: user))
        self.router = appRouter
    }

    private var flowContinuation: CheckedContinuation<FlowResult, Never>?
    private func updateFlowContinuation(_ continuation: CheckedContinuation<FlowResult, Never>?) {
        flowContinuation = continuation
    }

    func performFlow() async -> FlowResult {
        if flowContinuation != nil {
            assertionFailure("friends flow is already running")
        }
        return await withCheckedContinuation { continuation in
            Task {
                flowContinuation = continuation
                await presenter.start { [weak self] in
                    guard let self, let flowContinuation = await flowContinuation else { return }
                    await updateFlowContinuation(nil)
                    flowContinuation.resume(returning: .canceled)
                }
            }
        }
    }

    private func handleRepositoryError(_ error: RepositoryError) async {
        switch error {
        case .noConnection(let error):
            await showAlertWithOk(title: "no_connection_hint".localized, error: error)
        case .notAuthorized(let error):
            await router.alert(
                config: Alert.Config(
                    title: "alert_title_unauthorized".localized,
                    message: "\(error)",
                    actions: [
                        Alert.Action(title: "alert_action_auth".localized) { [weak self] _ in
                            guard let self else { return }
                            guard let flowContinuation = await flowContinuation else {
                                return assertionFailure("friends flow: got logout after flow is finished")
                            }
                            await updateFlowContinuation(nil)
                            flowContinuation.resume(returning: .loggedOut)
                        }
                    ]
                )
            )
        case .other(let error):
            await showAlertWithOk(title: "unknown_error_hint".localized, error: error)
        }
    }

    private func handleNoSuchUser(_ error: Error) async {
        await showAlertWithOk(title: "alert_action_no_such_user".localized, error: error)
    }

    private func handleNoSuchRequest(_ error: Error) async {
        await showAlertWithOk(title: "alert_action_no_such_request".localized, error: error)
    }

    private func showAlertWithOk(title: String, error: Error) async {
        await router.alert(
            config: Alert.Config(
                title: title,
                message: "\(error)",
                actions: [
                    Alert.Action(title: "alert_action_ok".localized)
                ]
            )
        )
    }

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
            case .alreadySent(let error):
                await showAlertWithOk(title: "alert_action_already_sent".localized, error: error)
            case .haveIncoming(let error):
                await showAlertWithOk(title: "alert_action_have_incoming".localized, error: error)
            case .alreadyFriends(let error):
                await showAlertWithOk(title: "alert_action_already_friends".localized, error: error)
            case .noSuchUser(let error):
                await handleNoSuchUser(error)
            case .other(let repositoryError):
                await handleRepositoryError(repositoryError)
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
            case .noSuchRequest(let error):
                await handleNoSuchRequest(error)
            case .other(let repositoryError):
                await handleRepositoryError(repositoryError)
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
            case .noSuchRequest(let error):
                await handleNoSuchRequest(error)
            case .other(let repositoryError):
                await handleRepositoryError(repositoryError)
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
            case .noSuchRequest(let error):
                await handleNoSuchRequest(error)
            case .other(let repositoryError):
                await handleRepositoryError(repositoryError)
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
            case .notAFriend(let error):
                await showAlertWithOk(title: "alert_action_not_a_friend".localized, error: error)
            case .noSuchUser(let error):
                await handleNoSuchUser(error)
            case .other(let repositoryError):
                await handleRepositoryError(repositoryError)
            }
        }
    }
}
