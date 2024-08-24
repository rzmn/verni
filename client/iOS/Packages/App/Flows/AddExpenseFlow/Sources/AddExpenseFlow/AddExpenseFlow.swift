import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD
internal import PickCounterpartyFlow
internal import Logging

public actor AddExpenseFlow {
    @MainActor var subject: Published<AddExpenseState>.Publisher {
        viewModel.$state
    }
    private let viewModel: AddExpenseViewModel

    private lazy var presenter = AddExpenseFlowPresenter(router: router, flow: self)
    private let spendingInteractions: SpendingInteractionsUseCase
    private let di: ActiveSessionDIContainer
    private let router: AppRouter
    private var subscriptions = Set<AnyCancellable>()
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter, counterparty: User?) async {
        self.di = di
        self.router = router
        spendingInteractions = di.spendingInteractionsUseCase()
        viewModel = await AddExpenseViewModel(counterparty: counterparty)
    }
}

// MARK: - Flow

extension AddExpenseFlow: Flow {
    public enum TerminationEvent {
        case canceledManually
        case expenseAdded
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
        await presenter.present()
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        subscriptions.removeAll()
        self.flowContinuation = nil
        if case .canceledManually = event {
        } else {
            await presenter.dismiss()
        }
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension AddExpenseFlow {
    @MainActor func cancel() {
        Task.detached {
            await self.presenter.dismiss()
            await self.handle(event: .canceledManually)
        }
    }

    @MainActor func addExpense() {
        Task.detached {
            await self.doAddExpense()
        }
    }

    @MainActor func pickCounterparty() {
        Task.detached {
            await self.doPickCounterparty()
        }
    }

    @MainActor func update(splitEqually: Bool) {
        viewModel.splitEqually = splitEqually
    }

    @MainActor func update(iOwe: Bool) {
        viewModel.expenseOwnership = iOwe ? .iOwe : .iAmOwned
    }

    @MainActor func update(description: String) {
        viewModel.description = description
    }

    @MainActor func update(expenseAmount: String) {
        viewModel.amount = expenseAmount
    }
}

// MARK: - Private

extension AddExpenseFlow {
    private func doAddExpense() async {
        let state = await viewModel.state
        guard let counterparty = state.counterparty else {
            return await presenter.needsPickCounterparty()
        }
        guard state.canConfirm else {
            return await presenter.errorHaptic()
        }
        let cost: Cost
        do {
            cost = try Cost(state.amount, format: .number)
        } catch {
            logE { "doAddExpense formatting failed: \(error)" }
            return await presenter.errorHaptic()
        }
        let spending = Spending(
            date: .now,
            details: state.expenseDescription,
            cost: cost,
            currency: state.selectedCurrency,
            participants: {
                let mine: Cost
                let counterparties: Cost
                if state.splitEqually {
                    mine = cost / 2
                    counterparties = cost / 2
                } else {
                    mine = cost
                    counterparties = cost
                }
                switch state.expenseOwnership {
                case .iOwe:
                    return [
                        counterparty.id: -counterparties,
                        di.userId: mine
                    ]
                case .iAmOwned:
                    return [
                        counterparty.id: counterparties,
                        di.userId: -mine
                    ]
                }
            }()
        )
        await presenter.presentLoading()
        let result = await spendingInteractions.create(spending: spending)
        switch result {
        case .success:
            await presenter.dismissLoading()
            await presenter.successHaptic()
            await handle(event: .expenseAdded)
        case .failure(let error):
            switch error {
            case .noSuchUser:
                await presenter.presentNoSuchUser()
            case .privacy:
                await presenter.privacyViolated()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    private func doPickCounterparty() async {
        let flow = await PickCounterpartyFlow(di: self.di, router: self.router)
        let result = await flow.perform()
        switch result {
        case .canceledManually:
            break
        case .picked(let counterparty):
            Task { @MainActor [unowned viewModel] in
                viewModel.counterparty = counterparty
            }
        }
    }
}

extension AddExpenseFlow: Loggable {}
