import UIKit
import Domain

private let contentOffset: CGFloat = 8
class FriendCell: UITableViewCell {
    private let content = FriendView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        content.reuse()
    }

    private func setupView() {
        for view in [content] {
            contentView.addSubview(view)
        }
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        backgroundView = UIView()
        selectedBackgroundView = UIView()
    }

    func render(item: FriendsState.Item) {
        content.render(item: item)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        content.frame = bounds.insetBy(dx: contentOffset, dy: contentOffset)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let contentFit = content.sizeThatFits(size)
        return CGSize(width: contentFit.width, height: contentFit.height + contentOffset * 2)
    }
}
