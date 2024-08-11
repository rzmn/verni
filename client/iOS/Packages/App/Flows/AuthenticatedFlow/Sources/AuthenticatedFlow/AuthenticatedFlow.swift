import UIKit
import Domain
import DI
import AppBase
internal import SignInFlow
internal import DesignSystem
internal import ProgressHUD
internal import AccountFlow
internal import FriendsFlow

public actor AuthenticatedFlow {
    private let presenter: AuthenticatedFlowPresenter
    private let accountFlow: AccountFlow
    private let friendsFlow: FriendsFlow

    private var urlResolvers = UrlResolverContainer()

    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        presenter = await AuthenticatedFlowPresenter(router: router)
        accountFlow = await AccountFlow(di: di, router: router)
        friendsFlow = await FriendsFlow(di: di, router: router)
        await urlResolvers.add(friendsFlow)
    }
}

extension AuthenticatedFlow: Flow {
    public enum TerminationEvent {
        case logout
    }

    public func perform(willFinish: ((TerminationEvent) async -> Void)?) async -> TerminationEvent {
        await presenter.start(tabs: [friendsFlow, accountFlow])
        return await withCheckedContinuation { continuation in
            flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
            Task.detached { [weak self] in
                guard let self else { return }
                let termination = await accountFlow.perform()
                guard let flowContinuation = await self.flowContinuation else {
                    return
                }
                switch termination {
                case .logout:
                    let result: FlowResult = .logout
                    await flowContinuation.willFinishHandler?(result)
                    flowContinuation.continuation.resume(returning: result)
                }
            }
        }
    }
}

extension AuthenticatedFlow: UrlResolver {
    public func canResolve(url: AppUrl) async -> Bool {
        await urlResolvers.canResolve(url: url)
    }
    
    public func resolve(url: AppUrl) async {
        await urlResolvers.resolve(url: url)
    }
}
