import Domain
import DI
import AppBase
import UIKit
internal import DesignSystem

actor QrPreviewFlow {
    enum QrGenerateError: Error {
        case invalidUrl
        case internalError(Error)
    }

    let state: QrPreviewState
    private let router: AppRouter
    private var continuation: Continuation?

    init(di: ActiveSessionDIContainer, router: AppRouter, profile: Profile) async throws {
        self.router = router
        guard let url = AppUrl.users(.show(profile.user.id)).url else {
            throw QrGenerateError.invalidUrl
        }
        let view: UIView
        do {
            view = try await di.qrInviteUseCase().createView(
                background: .p.backgroundContent,
                tint: .p.primary,
                url: url.absoluteString
            )
        } catch {
            throw QrGenerateError.internalError(error)
        }
        state = QrPreviewState(
            user: profile.user,
            qrView: view
        )
    }
}

extension QrPreviewFlow: Flow {
    typealias FlowResult = Void

    func perform(willFinish: ((FlowResult) async -> Void)?) async -> FlowResult {
        await withCheckedContinuation { continuation in
            self.continuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
            Task.detached { @MainActor [weak self] in
                guard let self else { return }
                let controller = QrPreviewViewController(model: self)
                await router.present(controller) { [weak self] in
                    guard let self else { return }
                    await handleContinuation()
                }
            }
        }
    }

    private func handleContinuation() async {
        guard let continuation else {
            return
        }
        self.continuation = nil
        await continuation.willFinishHandler?(())
        continuation.continuation.resume(returning: ())
    }
}
