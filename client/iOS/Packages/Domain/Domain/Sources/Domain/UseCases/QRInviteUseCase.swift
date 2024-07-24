import UIKit

public protocol QRInviteUseCase {
    func createView(background: UIColor, tint: UIColor, url: String, extraBottomPadding: CGFloat) async throws -> UIView
}
