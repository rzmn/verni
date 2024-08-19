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
    private let profileRepository: UsersRepository
    private lazy var presenter = AccountFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di
        editingUseCase = di.profileEditingUseCase()
        profileRepository = di.usersRepository()
        viewModel = await AccountViewModel(
            profile: await di.usersOfflineRepository().getHostInfo()
        )
    }
}

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
                await self.refresh()
            }
        }
    }

    private func refresh() async {
        Task { @MainActor [unowned self] in
            viewModel.content = .loading(previous: viewModel.state.info)
        }
        let result = await profileRepository.getHostInfo()
        Task { @MainActor [unowned self] in
            switch result {
            case .success(let profile):
                viewModel.content = .loaded(profile)
            case .failure(let error):
                await presenter.presentGeneralError(error)
            }
        }
    }

    func updateAvatar() async {
        await presenter.submitHaptic()
        let flow = UpdateAvatarFlow(di: di, router: router)
        guard case .success(let profile) = await flow.perform() else {
            return
        }
        Task { @MainActor [unowned self] in
            viewModel.content = .loaded(profile)
        }
    }

    func updateEmail() async {
        await presenter.submitHaptic()
        guard let profile = await getProfile() else {
            return
        }
        let flow = await UpdateEmailFlow(di: di, router: router, profile: profile)
        let handler = AnyFlowEventHandler(
            id: unsafeBitCast(self, to: Int.self),
            handle: { [unowned self] (event: UpdateEmailFlow.FlowEvent) in
                switch event {
                case .profileUpdated(let profile):
                    Task { @MainActor in
                        viewModel.content = .loaded(profile)
                    }
                }
            }
        )
        await flow.addHandler(handler: handler)
        _ = await flow.perform()
        await flow.removeHandler(handler: handler)
    }

    func updatePassword() async {
        await presenter.submitHaptic()
        guard let profile = await getProfile() else {
            return
        }
        let flow = await UpdatePasswordFlow(di: di, router: router, profile: profile)
        _ = await flow.perform()
    }

    func updateDisplayName() async {
        await presenter.submitHaptic()

        let flow = await UpdateDisplayNameFlow(di: di, router: router)
        let handler = AnyFlowEventHandler(
            id: unsafeBitCast(self, to: Int.self),
            handle: { [unowned self] (event: UpdateDisplayNameFlow.FlowEvent) in
                switch event {
                case .profileUpdated(let profile):
                    Task { @MainActor in
                        viewModel.content = .loaded(profile)
                    }
                }
            }
        )
        await flow.addHandler(handler: handler)
        _ = await flow.perform()
        await flow.removeHandler(handler: handler)
    }

    func showQr() async {
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

    func logout() async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: .logout)
    }
}

extension AccountFlow {
    private func getProfile() async -> Profile? {
        if let profile = await viewModel.state.info.value {
            return profile
        }
        await presenter.presentLoading()
        switch await profileRepository.getHostInfo() {
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
}
