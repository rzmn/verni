import Combine
import Domain
import DI
import DesignSystem
import UIKit

actor AccountModel {
    enum FlowResult {
        case loggedOut
        case canceled
    }
    let subject: CurrentValueSubject<AccountState, Never>
    private let qrPreviewModel: QrPreviewModel
    private let authorizedSessionRepository: UsersRepository
    private let appRouter: AppRouter

    init(di: ActiveSessionDIContainer, appRouter: AppRouter) async {
        self.appRouter = appRouter
        qrPreviewModel = await QrPreviewModel(router: appRouter)
        subject = CurrentValueSubject(AccountState(session: .initial))
        authorizedSessionRepository = di.authorizedSessionRepository()
    }

    private var flowContinuation: CheckedContinuation<FlowResult, Never>?

    func performFlow() async -> FlowResult {
        if flowContinuation != nil {
            assertionFailure("account flow is already running")
        }
        return await withCheckedContinuation { continuation in
            Task {
                flowContinuation = continuation
            }
        }
    }

    func refresh() async {
        switch await authorizedSessionRepository.getHostInfo() {
        case .success(let user):
            subject.send(AccountState(subject.value, session: .loaded(user)))
        case .failure(let error):
            switch error {
            case .noConnection(let error):
                subject.send(AccountState(subject.value, session: .failed(previous: subject.value.session, "\(error)")))
            case .notAuthorized(let error):
                await appRouter.alert(
                    config: Alert.Config(
                        title: "alert_title_unauthorized".localized,
                        message: "\(error)",
                        actions: [
                            Alert.Action(title: "alert_action_auth".localized) { [weak self] _ in
                                await self?.handle(flowResult: .loggedOut)
                            }
                        ]
                    )
                )
            case .other:
                await logout()
            }
        }
    }

    func showQr() async {
        guard case .loaded(let user) = subject.value.session else {
            return
        }
        await qrPreviewModel.start(user: user)
    }

    func logout() async {
        await appRouter.alert(
            config: Alert.Config(
                title: "account_logout".localized,
                message: "confirm_general_title".localized,
                actions: [
                    Alert.Action(title: "alert_action_ok".localized) { [weak self] _ in
                        await self?.handle(flowResult: .loggedOut)
                    },
                    Alert.Action(title: "alert_action_cancel".localized),
                ]
            )
        )
    }
}

extension AccountModel: CancelableFlow {
    func handleCancel() async {
        await handle(flowResult: .canceled)
    }

    private func handle(flowResult: FlowResult) async {
        guard let flowContinuation = flowContinuation else {
            return assertionFailure("account flow: got logout after flow is finished")
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: flowResult)
    }
}
