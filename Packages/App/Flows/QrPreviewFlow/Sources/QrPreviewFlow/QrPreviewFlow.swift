import Domain
import DI
import AppBase
import UIKit
internal import DesignSystem

public actor QrPreviewFlow {
    enum QrGenerateError: Error {
        case invalidUrl
        case internalError(Error)
    }

    let state: QrPreviewState
    private let router: AppRouter
    private var continuation: Continuation?

    public init(di: ActiveSessionDIContainer, router: AppRouter, profile: Profile) async throws {
        self.router = router
        guard let url = AppUrl.users(.show(profile.user.id)).url else {
            throw QrGenerateError.invalidUrl
        }
        let view: UIView
        do {
            view = try await di.qrInviteUseCase().createView(
                background: .palette.backgroundContent,
                tint: .palette.primary,
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
    public typealias FlowResult = Void

    public func perform() async -> FlowResult {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            Task {
                let controller = await QrPreviewViewController(model: self)
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
        continuation.resume(returning: ())
    }
}
