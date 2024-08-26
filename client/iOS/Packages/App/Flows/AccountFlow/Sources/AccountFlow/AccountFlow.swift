import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import UpdateEmailFlow
internal import UpdateDisplayNameFlow
internal import UpdatePasswordFlow
internal import QrPreviewFlow
internal import UpdateAvatarFlow

public actor AccountFlow {
    @MainActor var subject: Published<AccountState>.Publisher {
        viewModel.$state
    }

    private let viewModel: AccountViewModel
    private let di: ActiveSessionDIContainer
    private let router: AppRouter
    private let editingUseCase: ProfileEditingUseCase
    private let profileRepository: ProfileRepository
    private var subscriptions = Set<AnyCancellable>()
    private lazy var presenter = AccountFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di
        editingUseCase = di.profileEditingUseCase()
        profileRepository = di.profileRepository
        viewModel = await AccountViewModel(
            profile: await di.profileOfflineRepository().getProfile()
        )
    }

    public func setActive(_ active: Bool) async {
        let wasActive = !subscriptions.isEmpty
        guard active != wasActive else {
            return
        }
        if active {
            await profileRepository.profileUpdated()
                .map(Loadable.loaded)
                .assign(to: \.content, on: viewModel)
                .store(in: &subscriptions)
        } else {
            subscriptions.removeAll()
        }
    }
}

// MARK: - Flow

extension AccountFlow: TabEmbedFlow {
    @MainActor public func viewController() async -> Routable {
        await presenter.tabViewController
    }

    public enum TerminationEvent {
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
        Task { @MainActor [unowned self] in
            viewModel.content = .loading(previous: viewModel.state.info)
        }
        let result = await profileRepository.refreshProfile()
        Task { @MainActor [unowned self] in
            switch result {
            case .success(let profile):
                viewModel.content = .loaded(profile)
            case .failure(let error):
                await presenter.presentGeneralError(error)
            }
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
    @MainActor func updateAvatar() {
        Task.detached {
            await self.doUpdateAvatar()
        }
    }

    @MainActor func updateEmail() {
        Task.detached {
            await self.doUpdateEmail()
        }
    }

    @MainActor func updatePassword() {
        Task.detached {
            await self.doUpdatePassword()
        }
    }

    @MainActor func updateDisplayName() {
        Task.detached {
            await self.doUpdateDisplayName()
        }
    }

    @MainActor func showQr() {
        Task.detached {
            await self.doShowQr()
        }
    }

    @MainActor func logout() {
        Task.detached {
            await self.doLogout()
        }
    }
}

// MARK: - Private

extension AccountFlow {
    private func getProfile() async -> Profile? {
        if let profile = await viewModel.state.info.value {
            return profile
        }
        await presenter.presentLoading()
        switch await profileRepository.refreshProfile() {
        case .success(let profile):
            await presenter.dismissLoading()
            return profile
        case .failure(let error):
            switch error {
            case .noConnection:
                await presenter.presentNoConnection()
            case .notAuthorized:
                await presenter.presentNotAuthorized()
            case .other(let error):
                await presenter.presentInternalError(error)
            }
            return nil
        }
    }

    private func doUpdateAvatar() async {
        await presenter.submitHaptic()
        let flow = UpdateAvatarFlow(di: di, router: router)
        _ = await flow.perform()
    }

    private func doUpdateEmail() async {
        await presenter.submitHaptic()
        guard let profile = await getProfile() else {
            return
        }
        let flow = await UpdateEmailFlow(di: di, router: router, profile: profile)
        _ = await flow.perform()
    }

    private func doUpdatePassword() async {
        await presenter.submitHaptic()
        guard let profile = await getProfile() else {
            return
        }
        let flow = await UpdatePasswordFlow(di: di, router: router, profile: profile)
        _ = await flow.perform()
    }

    private func doUpdateDisplayName() async {
        await presenter.submitHaptic()
        let flow = await UpdateDisplayNameFlow(di: di, router: router)
        _ = await flow.perform()
    }

    private func doShowQr() async {
        await presenter.submitHaptic()
        guard let profile = await getProfile() else {
            return
        }
        let flow: QrPreviewFlow
        do {
            flow = try await QrPreviewFlow(di: di, router: router, profile: profile)
        } catch {
            return await presenter.presentInternalError(error)
        }
        await flow.perform()
    }

    private func doLogout() async {
        await handle(event: .logout)
    }
}
