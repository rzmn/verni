import UIKit
import Domain
import DI
import AppBase
internal import DesignSystem
internal import ProgressHUD
internal import AccountFlow
internal import FriendsFlow
internal import AddExpenseFlow

public actor AuthenticatedFlow {
    @MainActor var subject: Published<AuthenticatedState>.Publisher {
        viewModel.$state
    }
    private let viewModel: AuthenticatedViewModel

    private let accountFlow: AccountFlow
    private let friendsFlow: FriendsFlow
    private let router: AppRouter
    private let di: ActiveSessionDIContainer
    private lazy var presenter = AuthenticatedFlowPresenter(router: router, flow: self)

    private var urlResolvers = UrlResolverContainer()
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        accountFlow = await AccountFlow(di: di, router: router)
        friendsFlow = await FriendsFlow(di: di, router: router)
        viewModel = await AuthenticatedViewModel()
        self.di = di
        self.router = router
        await urlResolvers.add(friendsFlow)
    }
}

// MARK: - Flow

extension AuthenticatedFlow: Flow {
    public enum TerminationEvent {
        case logout
    }

    public func perform() async -> TerminationEvent {
        await presenter.start(
            tabs: viewModel.state.tabs.map { tab in
                switch tab {
                case .friends:
                    return friendsFlow
                case .account:
                    return accountFlow
                }
            }
        )
        return await withCheckedContinuation { continuation in
            flowContinuation = continuation
            Task.detached { [weak self] in
                guard let self else { return }
                switch await accountFlow.perform() {
                case .logout:
                    await handle(event: .logout)
                }
            }
        }
    }

    private func handle(event: TerminationEvent) {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension AuthenticatedFlow {
    @MainActor func addNewExpense() {
        Task.detached {
            await self.doAddExpense()
        }
    }

    @MainActor func selected(index: Int) {
        let state = viewModel.state
        guard state.tabs.count > index else {
            return
        }
        viewModel.activeTab = state.tabs[index]
    }
}

// MARK: - UrlResolver

extension AuthenticatedFlow: UrlResolver {
    public func canResolve(url: AppUrl) async -> Bool {
        await urlResolvers.canResolve(url: url)
    }
    
    public func resolve(url: AppUrl) async {
        await urlResolvers.resolve(url: url)
    }
}

// MARK: - Private

extension AuthenticatedFlow {
    private func doAddExpense() async {
        let flow = await AddExpenseFlow(di: di, router: router, counterparty: nil)
        _ = await flow.perform()
    }
}
