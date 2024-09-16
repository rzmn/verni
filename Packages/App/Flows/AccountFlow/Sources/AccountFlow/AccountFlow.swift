import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
internal import DesignSystem
internal import UpdateEmailFlow
internal import UpdateDisplayNameFlow
internal import UpdatePasswordFlow
internal import QrPreviewFlow
internal import UpdateAvatarFlow

public actor AccountFlow {
    private var _presenter: AccountPresenter?
    @MainActor private func presenter() async -> AccountPresenter {
        guard let presenter = await _presenter else {
            let presenter = await AccountPresenter(router: router, actions: makeActions())
            await mutate { s in
                s._presenter = presenter
            }
            return presenter
        }
        return presenter
    }
    private let viewModel: AccountViewModel
    private let di: ActiveSessionDIContainer
    private let router: AppRouter
    private let editingUseCase: ProfileEditingUseCase
    private let profileRepository: any ProfileRepository
    private var subscriptions = [any CancellableEventSource]()
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di
        editingUseCase = di.profileEditingUseCase()
        profileRepository = di.profileRepository
        viewModel = await AccountViewModel(
            profile: await di.profileOfflineRepository.getProfile()
        )
    }

    public func setActive(_ active: Bool) async {
        let wasActive = !subscriptions.isEmpty
        guard active != wasActive else {
            return
        }
        if active {
            subscriptions.append(
                await profileRepository.profileUpdated().subscribe { [viewModel] profile in
                    Task {
                        await viewModel.reload(profile: profile)
                    }
                }
            )
        } else {
            subscriptions.removeAll()
        }
    }
}

// MARK: - Flow

extension AccountFlow: TabEmbedFlow {
    @MainActor public func viewController() async -> Routable {
        await presenter().tabViewController
    }

    public enum TerminationEvent: Sendable {
        case logout
    }

    public func perform() async -> TerminationEvent {
        await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached {
                await self.startFlow()
            }
        }
    }

    private func startFlow() async {
        await viewModel.setLoading()
        do {
            let profile = try await profileRepository.refreshProfile()
            await viewModel.reload(profile: profile)
        } catch {
            await presenter().presentGeneralError(error)
        }
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        subscriptions.removeAll()
        self.flowContinuation = nil
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension AccountFlow {
    @MainActor private func makeActions() async -> AccountViewActions {
        AccountViewActions(state: viewModel.$state) { action in
            Task.detached { [weak self] in
                guard let self else { return }
                switch action {
                case .onUpdateAvatarTap:
                    await updateAvatar()
                case .onUpdateEmailTap:
                    await updateEmail()
                case .onUpdatePasswordTap:
                    await updatePassword()
                case .onUpdateDisplayNameTap:
                    await updateDisplayName()
                case .onShowQrTap:
                    await showQr()
                case .onLogoutTap:
                    await logout()
                }
            }
        }
    }
}

// MARK: - Private

extension AccountFlow {
    private func getProfile() async -> Profile? {
        if let profile = await viewModel.state.info.value {
            return profile
        }
        await presenter().presentLoading()
        do {
            let profile = try await profileRepository.refreshProfile()
            await presenter().dismissLoading()
            return profile
        } catch {
            switch error {
            case .noConnection:
                await presenter().presentNoConnection()
            case .notAuthorized:
                await presenter().presentNotAuthorized()
            case .other(let error):
                await presenter().presentInternalError(error)
            }
            return nil
        }
    }

    private func updateAvatar() async {
        await presenter().submitHaptic()
        let flow = await UpdateAvatarFlow(di: di, router: router)
        _ = await flow.perform()
    }

    private func updateEmail() async {
        await presenter().submitHaptic()
        guard let profile = await getProfile() else {
            return
        }
        let flow = await UpdateEmailFlow(di: di, router: router, profile: profile)
        _ = await flow.perform()
    }

    private func updatePassword() async {
        await presenter().submitHaptic()
        guard let profile = await getProfile() else {
            return
        }
        let flow = await UpdatePasswordFlow(di: di, router: router, profile: profile)
        _ = await flow.perform()
    }

    private func updateDisplayName() async {
        await presenter().submitHaptic()
        let flow = await UpdateDisplayNameFlow(di: di, router: router)
        _ = await flow.perform()
    }

    private func showQr() async {
        await presenter().submitHaptic()
        guard let profile = await getProfile() else {
            return
        }
        let flow: QrPreviewFlow
        do {
            flow = try await QrPreviewFlow(di: di, router: router, profile: profile)
        } catch {
            return await presenter().presentInternalError(error)
        }
        await flow.perform()
    }

    private func logout() async {
        await handle(event: .logout)
    }
}
