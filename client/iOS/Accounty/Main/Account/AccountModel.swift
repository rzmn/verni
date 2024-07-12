import Combine
import Domain
import DI
import DesignSystem
import UIKit

actor AccountModel {
    let subject: CurrentValueSubject<AccountState, Never>
    private let qrPreviewModel: QrPreviewModel
    private let authorizedSessionRepository: UsersRepository
    private let appRouter: AppRouter
    private weak var appModel: AppModel?

    init(di: ActiveSessionDIContainer, appRouter: AppRouter, state: AccountState? = nil) async {
        self.appRouter = appRouter
        qrPreviewModel = await QrPreviewModel(router: appRouter)
        if let state {
            subject = CurrentValueSubject(state)
        } else {
            subject = CurrentValueSubject(AccountState(session: .initial))
        }
        authorizedSessionRepository = di.authorizedSessionRepository()
    }

    func setAppModel(_ appModel: AppModel) {
        self.appModel = appModel
    }

    func start() async {
        await refresh()
    }

    func refresh() async {
        switch await authorizedSessionRepository.getHostInfo() {
        case .success(let user):
            subject.send(AccountState(subject.value, session: .loaded(user)))
        case .failure(let error):
            subject.send(AccountState(subject.value, session: .failed(previous: subject.value.session, "\(error)")))
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
                    Alert.Action(
                        title: "alert_action_ok".localized,
                        handler: { alert in
                            Task { [weak self] in
                                await self?.appModel?.logout()
                            }
                        }
                    ),
                    Alert.Action(
                        title: "alert_action_cancel".localized,
                        handler: { _ in }
                    ),
                ]
            )
        )
    }
}
