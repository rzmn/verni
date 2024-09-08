import UIKit

public protocol QRInviteUseCase: Sendable {
    func createView(background: UIColor, tint: UIColor, url: String) async throws -> UIView
}
