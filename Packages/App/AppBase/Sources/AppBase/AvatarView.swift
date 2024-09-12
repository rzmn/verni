import UIKit
import Domain

private extension String {
    func image(fitSize: CGSize?) -> UIImage? {
        let size = fitSize ?? CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: size.width)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public class AvatarView: UIImageView {
    public static var repository: AvatarsRepository?

    private var task: Task<Void, Never>?

    public var fitSize: CGSize? {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var avatarId: Avatar.ID? {
        didSet {
            task?.cancel()
            guard let avatarId else {
                Task.detached { @MainActor in
                    self.image = "🥷".image(fitSize: self.fitSize)
                }
                return
            }
            task = Task.detached {
                guard let repository = await Self.repository else {
                    return
                }
                guard let data = await repository.get(id: avatarId) else {
                    return
                }
                if Task.isCancelled {
                    return
                }
                Task { @MainActor in
                    self.image = UIImage(data: data)
                }
            }
        }
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let fitSize else {
            return super.sizeThatFits(size)
        }
        return fitSize
    }
}
