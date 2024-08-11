import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem

public actor AccountFlow {
    let subject = CurrentValueSubject<AccountState, Never>(.initial)

    private let di: ActiveSessionDIContainer
    private let router: AppRouter
    private let editingUseCase: ProfileEditingUseCase
    private let profileRepository: UsersRepository
    private let profileOfflineRepository: UsersOfflineRepository
    private lazy var presenter = AccountFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        self.di = di
        editingUseCase = di.profileEditingUseCase()
        profileRepository = di.usersRepository()
        profileOfflineRepository = di.usersOfflineRepository()
    }
}

extension AccountFlow: TabEmbedFlow {
    @MainActor public func viewController() async -> Routable {
        await presenter.tabViewController
    }

    public enum TerminationEvent {
        case logout
    }
    
    public func perform(willFinish: ((TerminationEvent) async -> Void)?) async -> TerminationEvent {
        subject.send(AccountState(info: .loading(previous: subject.value.info)))
        if let profile = await profileOfflineRepository.getHostInfo() {
            subject.send(AccountState(info: .loaded(profile)))
        }
        Task.detached { [weak self] in
            guard let self else { return }
            switch await profileRepository.getHostInfo() {
            case .success(let profile):
                subject.send(AccountState(info: .loaded(profile)))
            case .failure(let error):
                switch error {
                case .noConnection:
                    subject.send(AccountState(info: .failed(previous: subject.value.info, "no_connection_hint".localized)))
                case .notAuthorized:
                    await presenter.presentNotAuthorized()
                case .other(let error):
                    await presenter.presentInternalError(error)
                }
            }
        }
        return await withCheckedContinuation { continuation in
            self.flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
        }
    }

    func updateAvatar() async {
        await presenter.submitHaptic()
        let flow = UpdateAvatarFlow(di: di, router: router)
        guard case .success(let profile) = await flow.perform() else {
            return
        }
        subject.send(AccountState(info: .loaded(profile)))
    }

    func updateEmail() async {
        await presenter.submitHaptic()
        let profile: Profile
        if case .loaded(let _profile) = subject.value.info {
            profile = _profile
        }
        else if let _profile = await profileOfflineRepository.getHostInfo() {
            profile = _profile
        } else {
            await presenter.presentLoading()
            switch await profileRepository.getHostInfo() {
            case .success(let _profile):
                profile = _profile
            case .failure(let error):
                switch error {
                case .noConnection:
                    await presenter.presentNoConnection()
                case .notAuthorized:
                    await presenter.presentNotAuthorized()
                case .other(let error):
                    await presenter.presentInternalError(error)
                }
                return
            }
        }
        let flow = UpdateEmailFlow(di: di, router: router, profile: profile)
        _ = await flow.perform(
            willFinish: { [weak self] result in
                guard let self else { return }
                guard case .success(let profile) = result else {
                    return
                }
                subject.send(AccountState(info: .loaded(profile)))
            }
        )
    }

    func updatePassword() async {
        await presenter.submitHaptic()
        let profile: Profile
        if case .loaded(let _profile) = subject.value.info {
            profile = _profile
        }
        else if let _profile = await profileOfflineRepository.getHostInfo() {
            profile = _profile
        } else {
            await presenter.presentLoading()
            switch await profileRepository.getHostInfo() {
            case .success(let _profile):
                profile = _profile
            case .failure(let error):
                switch error {
                case .noConnection:
                    await presenter.presentNoConnection()
                case .notAuthorized:
                    await presenter.presentNotAuthorized()
                case .other(let error):
                    await presenter.presentInternalError(error)
                }
                return
            }
        }
        let flow = UpdatePasswordFlow(di: di, router: router, profile: profile)
        _ = await flow.perform(
            willFinish: { [weak self] result in
                guard let self else { return }
                guard case .success(let profile) = result else {
                    return
                }
                subject.send(AccountState(info: .loaded(profile)))
            }
        )
    }

    func updateDisplayName() async {
        await presenter.submitHaptic()
        let flow = UpdateDisplayNameFlow(di: di, router: router)
        _ = await flow.perform(
            willFinish: { [weak self] result in
                guard let self else { return }
                guard case .success(let profile) = result else {
                    return
                }
                subject.send(AccountState(info: .loaded(profile)))
            }
        )
    }

    func showQr() async {
        guard let profile = subject.value.info.value else {
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
        let result: FlowResult = .logout
        await flowContinuation.willFinishHandler?(result)
        flowContinuation.continuation.resume(returning: result)
    }
}
