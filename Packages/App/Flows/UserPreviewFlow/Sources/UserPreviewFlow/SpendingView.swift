import UIKit
import Domain
internal import DesignSystem

class SpendingView: UIView {
    static let dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    private let category = {
        let view = UIImageView()
        view.image = UIImage(systemName: "dollarsign")
        view.tintColor = .p.accent
        view.contentMode = .scaleAspectFit
        return view
    }()
    private let title = {
        let label = UILabel()
        label.font = .p.text
        label.textColor = .p.primary
        return label
    }()
    private let date = {
        let label = UILabel()
        label.font = .p.subtitle
        label.textColor = .p.primary
        return label
    }()
    private let ownership = {
        let label = UILabel()
        label.font = .p.title3
        label.textColor = .p.primary
        return label
    }()
    private let amount = {
        let label = UILabel()
        label.font = .p.text
        label.textColor = .p.primary
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        backgroundColor = .p.backgroundContent
        [category, title, date, ownership, amount].forEach(addSubview)
    }

    func reuse() {
        // empty
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let categorySize: CGFloat = 40
        let categoryPadding = (bounds.height - categorySize) / 2
        category.frame = CGRect(
            x: categoryPadding,
            y: categoryPadding,
            width: categorySize,
            height: categorySize
        )
        let ownershipSize = ownership.sizeThatFits(bounds.size)
        let amountSize = amount.sizeThatFits(bounds.size)
        let rightContentHeight = ownershipSize.height + amountSize.height
        ownership.frame = CGRect(
            x: bounds.width - .p.defaultHorizontal - ownershipSize.width,
            y: bounds.midY - rightContentHeight / 2,
            width: ownershipSize.width,
            height: ownershipSize.height
        )
        amount.frame = CGRect(
            x: bounds.width - .p.defaultHorizontal - amountSize.width,
            y: ownership.frame.maxY,
            width: amountSize.width,
            height: amountSize.height
        )
        let paddedBounds = CGSize(
            width: min(
                ownership.frame.minX,
                amount.frame.minX
            ) - .p.defaultHorizontal - category.frame.maxX,
            height: bounds.height)
        let titleSize = title.sizeThatFits(paddedBounds)
        let dateSize = date.sizeThatFits(paddedBounds)
        let leftContentHeight = titleSize.height + dateSize.height
        title.frame = CGRect(
            x: category.frame.maxX + .p.defaultHorizontal,
            y: bounds.midY - leftContentHeight / 2,
            width: titleSize.width,
            height: titleSize.height
        )
        date.frame = CGRect(
            x: category.frame.maxX + .p.defaultHorizontal,
            y: title.frame.maxY,
            width: dateSize.width,
            height: dateSize.height
        )
    }

    func render(spending: UserPreviewState.SpendingPreview) {
        title.text = spending.title
        date.text = Self.dateFormatter.string(from: spending.date)
        amount.text = "\(abs(spending.personalAmount)) \(spending.currency.stringValue)"
        if spending.iOwe {
            ownership.text = "expense_i_owe".localized
            ownership.textColor = .p.positive
        } else {
            ownership.text = "expense_i_am_owed".localized
            ownership.textColor = .p.destructive
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: 52)
    }
}
