import UIKit
import Domain
import DI
import AppBase
import AsyncExtensions
internal import DesignSystem
internal import ProgressHUD
internal import AccountFlow
internal import FriendsFlow
internal import AddExpenseFlow

public actor AuthenticatedFlow {
    private lazy var presenter = AsyncLazyObject {
        AuthenticatedPresenter(
            router: self.router,
            actions: await MainActor.run {
                self.makeActions()
            }
        )
    }
    private let viewModel: AuthenticatedViewModel

    private let accountFlow: AccountFlow
    private let friendsFlow: FriendsFlow
    private let router: AppRouter
    private let di: ActiveSessionDIContainer

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
    public enum TerminationEvent: Sendable {
        case logout
    }

    public func perform() async -> TerminationEvent {
        await presenter.value.start(
            tabs: viewModel.state.tabs.map { tab in
                switch tab {
                case .friends:
                    return friendsFlow
                case .account:
                    return accountFlow
                }
            }
        )
        await di.pushRegistrationUseCase().askForPushToken()
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
    @MainActor private func makeActions() -> AuthenticatedViewActions {
        AuthenticatedViewActions(state: viewModel.$state) { [weak self] action in
            guard let self else { return }
            switch action {
            case .onAddExpenseTap:
                Task.detached {
                    await self.addExpense()
                }
            case .onTabSelected(let index):
                let state = viewModel.state
                guard state.tabs.count > index else {
                    return
                }
                let oldTab = state.activeTab
                let newTab = state.tabs[index]
                guard oldTab != newTab else {
                    return
                }
                viewModel.activeTab = newTab
                Task.detached { [weak self] in
                    guard let self else { return }
                    switch oldTab {
                    case .friends:
                        await friendsFlow.setActive(false)
                    case .account:
                        await accountFlow.setActive(false)
                    }
                    switch newTab {
                    case .friends:
                        await friendsFlow.setActive(true)
                    case .account:
                        await accountFlow.setActive(true)
                    }
                }
            }
        }
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
    private func addExpense() async {
        let flow = await AddExpenseFlow(di: di, router: router, counterparty: nil)
        _ = await flow.perform()
    }
}
