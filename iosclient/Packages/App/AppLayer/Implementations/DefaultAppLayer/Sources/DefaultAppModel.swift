import Entities
import UIKit
import AppBase
import SwiftUI
import AppLayer
import DomainLayer
import DesignSystem
import AuthWelcomeScreen
import IncomingPushUseCase
internal import Logging
internal import Convenience

public actor DefaultAppModel {
    private let store: Store<AppState, AppAction>
    private let pushRegistry: Task<PushRegistry, Never>
    private let domain: Task<SandboxDomainLayer, Never>
    private let urlProvider: UrlProvider

    @MainActor public init(
        domain: Task<SandboxDomainLayer, Never>,
        urlProvider: UrlProvider
    ) {
        CustomFonts.registerCustomFonts(class: DefaultAppModel.self)
        self.domain = domain
        self.urlProvider = urlProvider
        store = Store(
            state: DefaultAppModel.initialState,
            reducer: DefaultAppModel.reducer
        )
        pushRegistry = Task {
            await PushRegistry(
                logger: domain.value.infrastructure.logger
                    .with(scope: .pushNotifications)
            )
        }
        store.append(
            handler: AppSideEffects(
                store: store,
                domain: domain,
                pushRegistry: pushRegistry,
                urlProvider: urlProvider
            ),
            keepingUnique: true
        )
    }
}

extension DefaultAppModel: AppModel {
    @MainActor public func view() -> AppView {
        AppView(store: self.store)
    }

    public func registerPushToken(token: Data) async {
        await pushRegistry.value.registerPushToken(token: token)
    }

    public func handle(push: UNMutableNotificationContent) async {
        let domain = await domain.value
        let session: HostedDomainLayer
        do {
            session = try await domain.authUseCase().awake()
        } catch {
            switch error {
            case .hasNoSession:
                return
            case .internalError(let error):
                return domain.infrastructure.logger.logE { "handling push: awakening session error: \(error)" }
            }
        }
        let content: PushContent
        do {
            content = try await session
                .incomingPushUseCase()
                .handle(rawPushPayload: push.userInfo)
        } catch {
            switch error {
            case .internalError(let error):
                return domain.infrastructure.logger.logE { "handling push \(push.userInfo) error: \(error)" }
            }
        }
        switch content {
        case .spendingCreated(let payload):
            push.title = .pushNewSpending
            let shareString = { () -> String in
                if payload.share > 0 {
                    return .addExpenseYouOwe(counterparty: payload.currency.formatted(amount: abs(payload.share)))
                } else {
                    return .addExpenseOwesYou(counterparty: payload.currency.formatted(amount: abs(payload.share)))
                }
            }
            if let groupName = payload.groupName {
                switch groupName {
                case .opponentName(let name):
                    if payload.share > 0 {
                        push.subtitle = .spending(paidBy: .you, amount: payload.currency.formatted(amount: payload.amount))
                    } else {
                        push.subtitle = .spending(paidBy: name, amount: payload.currency.formatted(amount: payload.amount))
                    }
                case .groupName(let string):
                    if payload.share > 0 {
                        push.subtitle = .spending(paidBy: .you, amount: payload.currency.formatted(amount: payload.amount))
                    } else {
                        push.subtitle = .spending(paidBy: "\"\(string)\"", amount: payload.currency.formatted(amount: payload.amount))
                    }
                }
                push.body = shareString()
            } else {
                push.subtitle = shareString()
            }
        case .spendingGroupCreated(let spendingGroupCreated):
            push.title = .pushNewSpendingGroup
            if let groupName = spendingGroupCreated.groupName {
                push.subtitle = "Group name: \(groupName)"
            }
        }
        return
    }
}
