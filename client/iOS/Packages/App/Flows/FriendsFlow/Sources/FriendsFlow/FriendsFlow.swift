import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD

public actor FriendsFlow {
    let subject = CurrentValueSubject<FriendsState, Never>(.initial)

    private let di: ActiveSessionDIContainer
    private let router: AppRouter
    private let editingUseCase: ProfileEditingUseCase
    private let profileRepository: UsersRepository
    private let profileOfflineRepository: UsersOfflineRepository
    private let friendListRepository: FriendsRepository
    private lazy var presenter = FriendsFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di
        editingUseCase = di.profileEditingUseCase()
        profileRepository = di.usersRepository()
        friendListRepository = di.friendListRepository()
        profileOfflineRepository = di.usersOfflineRepository()
    }

    func addViaQr() async {
        let flow = await AddFriendByQrFlow(router: router)
        switch await flow.perform(willFinish: nil) {
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

    func refresh() async {
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
        await friendListRepository.getFriends(set: [.friends, .incoming, .pending]).map { data in
            FriendsState.Content(
                upcomingRequests: data[.incoming] ?? [],
                pendingRequests: data[.pending] ?? [],
                friends: data[.friends] ?? []
            )
        }
    }
}

extension FriendsFlow: TabEmbedFlow {
    public func perform(willFinish: ((Int) async -> Void)?) async -> Int {
        .zero
    }
    
    public typealias FlowResult = Int

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
