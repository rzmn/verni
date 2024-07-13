import Domain
import DI
import Base

protocol CancelableFlow: AnyObject {
    func handleCancel() async
}

actor MainModel {
    enum FlowResult {
        case loggedOut
    }
    private lazy var presenter = MainPresenter(model: self, appRouter: appRouter)
    private let appRouter: AppRouter
    private let logoutUseCase: LogoutUseCase
    private weak var appModel: AppModel?
    let friendsModel: FriendsModel
    let accountModel: AccountModel

    init(di: ActiveSessionDIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        logoutUseCase = di.logoutUseCase()
        friendsModel = await FriendsModel(di: di, appRouter: appRouter)
        accountModel = await AccountModel(di: di, appRouter: appRouter)
    }

    private var flowContinuation: CheckedContinuation<FlowResult, Never>?
    private func updateFlowContinuation(_ continuation: CheckedContinuation<FlowResult, Never>?) {
        flowContinuation = continuation
    }
    func performFlow() async -> FlowResult {
        await presenter.start()
        Task.detached {
            switch await self.accountModel.performFlow() {
            case .loggedOut:
                await self.logout(sender: self.accountModel)
            case .canceled:
                break
            }
        }
        Task.detached {
            switch await self.friendsModel.performFlow() {
            case .loggedOut:
                await self.logout(sender: self.friendsModel)
            case .canceled:
                break
            }
        }
        return await withCheckedContinuation { continuation in
            Task {
                self.flowContinuation = continuation
            }
        }
    }

    private func logout<T: AnyObject & CancelableFlow>(sender: T) async {
        guard let flowContinuation else {
            return assertionFailure("main flow: already finished")
        }
        updateFlowContinuation(nil)
        await logoutUseCase.logout()
        for handler in ([self.accountModel, self.friendsModel] as [AnyObject & CancelableFlow]) where handler !== sender {
            await handler.handleCancel()
        }
        flowContinuation.resume(returning: .loggedOut)
    }
}

extension MainModel: UrlResolver {
    func canResolve(url: InternalUrl) async -> Bool {
        await friendsModel.canResolve(url: url)
    }

    func resolve(url: InternalUrl) async {
        await friendsModel.resolve(url: url)
    }
}
