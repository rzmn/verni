import UIKit
import Domain

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
                    self.image = nil
                }
                return
            }
            task = Task.detached {
                guard let repository = await Self.repository else {
                    return
                }
                let result = await repository.get(id: avatarId)
                if Task.isCancelled {
                    return
                }
                Task { @MainActor in
                    switch result {
                    case .success(let data):
                        let image = UIImage(data: data)
                        self.image = image
                    case .failure:
                        self.image = nil
                    }
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
