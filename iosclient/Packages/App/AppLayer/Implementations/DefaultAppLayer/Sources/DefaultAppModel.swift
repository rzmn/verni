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

    @MainActor public init(
        domain: Task<SandboxDomainLayer, Never>
    ) {
        CustomFonts.registerCustomFonts(class: DefaultAppModel.self)
        self.domain = domain
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
                pushRegistry: pushRegistry
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
        case .spendingCreated(let spendingCreated):
            push.title = .pushNewSpending
            if let groupName = spendingCreated.groupName {
                push.subtitle = "\(spendingCreated.spendingName) (in \(groupName))"
            } else {
                push.subtitle = spendingCreated.spendingName
            }
            push.body = spendingCreated.currency.formatted(amount: spendingCreated.amount)
        case .spendingGroupCreated(let spendingGroupCreated):
            push.title = .pushNewSpendingGroup
            if let groupName = spendingGroupCreated.groupName {
                push.subtitle = "Group name: \(groupName)"
            }
        }
    }
}
