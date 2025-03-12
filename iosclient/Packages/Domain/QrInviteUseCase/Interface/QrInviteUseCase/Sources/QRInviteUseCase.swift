import UIKit

public protocol QRInviteUseCase: Sendable {
    @MainActor func generate(background: UIColor, tint: UIColor, size: Int, text: String) async throws -> Data
}
