import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD
internal import PickCounterpartyFlow
internal import Logging

private extension Dictionary where Key == User.ID, Value == Cost {
    static func spendingBalance(
        cost: Cost,
        myId: User.ID,
        counterpartyId: User.ID,
        expenseOwnership: AddExpenseState.ExpenseOwnership,
        splitEqually: Bool
    ) -> Self {
        let mine: Cost
        let counterparties: Cost
        if splitEqually {
            mine = cost / 2
            counterparties = cost / 2
        } else {
            mine = cost
            counterparties = cost
        }
        switch expenseOwnership {
        case .iOwe:
            return [
                counterpartyId: -counterparties,
                myId: mine
            ]
        case .iAmOwned:
            return [
                counterpartyId: counterparties,
                myId: -mine
            ]
        }
    }
}

public actor AddExpenseFlow {
    private var _presenter: AddExpensePresenter?
    @MainActor private func presenter() async -> AddExpensePresenter {
        guard let presenter = await _presenter else {
            let presenter = await AddExpensePresenter(router: router, actions: makeActions())
            await mutate { s in
                s._presenter = presenter
            }
            return presenter
        }
        return presenter
    }
    private let viewModel: AddExpenseViewModel
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
    public enum TerminationEvent: Sendable {
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
        await presenter().present()
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        subscriptions.removeAll()
        self.flowContinuation = nil
        if case .canceledManually = event {
        } else {
            await presenter().dismiss()
        }
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension AddExpenseFlow {
    @MainActor private func makeActions() async -> AddExpenseViewActions {
        AddExpenseViewActions(state: viewModel.$state) { [weak self] action in
            guard let self else { return }
            switch action {
            case .onCancelTap:
                Task.detached {
                    await self.presenter().dismiss()
                    await self.handle(event: .canceledManually)
                }
            case .onDoneTap:
                Task.detached {
                    await self.addExpense()
                }
            case .onPickCounterpartyTap:
                Task.detached {
                    await self.pickCounterparty()
                }
            case .onSplitRuleTap(let equally):
                viewModel.splitEqually = equally
            case .onOwnershipTap(let iOwe):
                viewModel.expenseOwnership = iOwe ? .iOwe : .iAmOwned
            case .onDescriptionChanged(let expenseDescription):
                viewModel.description = expenseDescription
            case .onExpenseAmountChanged(let expenseAmount):
                viewModel.amount = expenseAmount
            }
        }
    }
}

// MARK: - Private

extension AddExpenseFlow {
    private func addExpense() async {
        let state = await viewModel.state
        guard let counterparty = state.counterparty else {
            return await presenter().needsPickCounterparty()
        }
        guard state.canConfirm else {
            return await presenter().errorHaptic()
        }
        let cost: Cost
        do {
            cost = try Cost(state.amount, format: .number)
        } catch {
            return await presenter().errorHaptic()
        }
        let spending = Spending(
            date: .now,
            details: state.expenseDescription,
            cost: cost,
            currency: state.selectedCurrency,
            participants: .spendingBalance(
                cost: cost,
                myId: di.userId,
                counterpartyId: counterparty.id,
                expenseOwnership: state.expenseOwnership,
                splitEqually: state.splitEqually
            )
        )
        await presenter().presentLoading()
        do {
            try await spendingInteractions.create(spending: spending)
            await presenter().dismissLoading()
            await presenter().successHaptic()
            await handle(event: .expenseAdded)
        } catch {
            switch error {
            case .noSuchUser:
                await presenter().presentNoSuchUser()
            case .privacy:
                await presenter().privacyViolated()
            case .other(let error):
                await presenter().presentGeneralError(error)
            }
        }
    }

    private func pickCounterparty() async {
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
