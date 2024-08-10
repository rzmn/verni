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
    private lazy var presenter = FriendsFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di
        editingUseCase = di.profileEditingUseCase()
        profileRepository = di.usersRepository()
        profileOfflineRepository = di.usersOfflineRepository()
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
