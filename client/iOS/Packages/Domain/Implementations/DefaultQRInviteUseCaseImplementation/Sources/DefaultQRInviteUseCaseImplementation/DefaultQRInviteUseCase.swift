import UIKit
import Domain
internal import QRCode

public class DefaultQRInviteUseCase: QRInviteUseCase {
    public init() {}

    @MainActor
    public func createView(background: UIColor, tint: UIColor, url: String) async throws -> UIView {
        let image = await Task {
            try QRCode.build
                .text(url)
                .quietZonePixelCount(4)
                .foregroundColor(tint.cgColor)
                .backgroundColor(background.cgColor)
                .background.cornerRadius(4)
                .onPixels.shape(QRCode.PixelShape.RoundedPath())
                .eye.shape(QRCode.EyeShape.Squircle())
                .generate.image(dimension: 1600)
        }.result
        return QrCodeView(
            image: try image.get()
        )
    }
}

class QrCodeView: UIView {
    private let imageView = UIImageView()

    init(image: CGImage) {
        super.init(frame: .zero)
        imageView.image = UIImage(cgImage: image)
        [imageView].forEach(addSubview)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side = min(bounds.size.width, bounds.size.height)
        imageView.frame = CGRect(
            x: bounds.midX - side / 2,
            y: 0,
            width: side,
            height: side
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let side = min(size.width, size.height)
        return CGSize(
            width: side,
            height: side
        )
    }
}
