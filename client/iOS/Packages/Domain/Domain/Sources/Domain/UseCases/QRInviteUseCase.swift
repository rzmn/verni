import UIKit

public protocol QRInviteUseCase {
    func createView(background: UIColor, tint: UIColor, url: String) async throws -> UIView
}
