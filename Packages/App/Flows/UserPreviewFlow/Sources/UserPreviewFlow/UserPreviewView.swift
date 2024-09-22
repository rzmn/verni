import UIKit
import Combine
import AppBase
import Domain
internal import DesignSystem

private extension Placeholder.Config {
    static var listIsEmpty: Self {
        Self(
            message: "friend_list_empty_placeholder".localized,
            icon: UIImage(systemName: "person.crop.rectangle.badge.plus")
        )
    }
}

class UserPreviewView: View<UserPreviewViewActions> {
    private let avatar = {
        let size: CGFloat = 88
        let frame = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        let view = AvatarView(frame: frame)
        view.fitSize = frame.size
        view.layer.masksToBounds = true
        view.layer.cornerRadius = size / 2
        view.contentMode = .scaleAspectFill
        return view
    }()
    private let name = {
        let label = UILabel()
        label.textColor = .p.primary
        label.font = .p.title2
        label.textAlignment = .center
        return label
    }()
    private let table = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .p.background
        table.backgroundView = UIView()
        table.separatorColor = .clear
        table.register(SpendingCell.self)
        return table
    }()
    private lazy var cellProvider: DataSource.CellProvider = { [unowned self] tableView, indexPath, _ in
        let cell = tableView.dequeue(SpendingCell.self, at: indexPath)
        let item = items(in: sections[indexPath.section])[indexPath.row]
        cell.render(spending: item)
        cell.contentView.backgroundColor = .p.backgroundContent
        return cell
    }
    private lazy var dataSource = DataSource(
        tableView: table,
        cellProvider: cellProvider
    )
    private let emptyPlaceholder = Placeholder(config: .listIsEmpty)
    private var subscriptions = Set<AnyCancellable>()
    private var state: UserPreviewState? {
        didSet {
            guard let state else { return }
            render(state: state, animated: oldValue != nil)
        }
    }

    override func setupView() {
        backgroundColor = .p.background
        for view in [name, avatar, table, emptyPlaceholder] {
            addSubview(view)
        }
        dataSource.defaultRowAnimation = .bottom
        model.state
            .map { $0 as UserPreviewState? }
            .assign(to: \.state, on: self)
            .store(in: &subscriptions)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let avatarSize = avatar.sizeThatFits(bounds.size)
        avatar.frame = CGRect(
            x: bounds.midX - avatarSize.width / 2,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: avatarSize.width,
            height: avatarSize.height
        )
        let loginSize = name.sizeThatFits(bounds.size)
        name.frame = CGRect(
            x: bounds.midX - loginSize.width / 2,
            y: avatar.frame.maxY + .p.vButtonSpacing,
            width: loginSize.width,
            height: loginSize.height
        )
        table.frame = CGRect(
            x: 0,
            y: name.frame.maxY,
            width: bounds.width,
            height: bounds.height - name.frame.maxY - safeAreaInsets.bottom
        )
        emptyPlaceholder.frame = table.frame
    }

    private func render(state: UserPreviewState, animated: Bool) {
        avatar.avatarId = state.user.avatar?.id
        name.text = state.userNameText
        dataSource.apply(.snapshot(sections: sections, cells: { section in
            items(in: section).map(\.id)
        }), animatingDifferences: animated && !table.isDragging && !table.isDecelerating)
        switch state.spenginds {
        case .initial:
            emptyPlaceholder.isHidden = true
        case .loaded:
            let emptyState = sections.isEmpty
            if emptyState {
                emptyPlaceholder.render(.listIsEmpty)
            }
            emptyPlaceholder.isHidden = !emptyState
        case .loading(let previous):
            if let error = previous.error {
                emptyPlaceholder.render(
                    Placeholder.Config(
                        message: error.hint,
                        icon: error.iconName.flatMap(UIImage.init(systemName:))
                    )
                )
                emptyPlaceholder.isHidden = false
            } else if case .initial = previous {
                emptyPlaceholder.isHidden = true
            } else {
                let emptyState = sections.isEmpty
                if emptyState {
                    emptyPlaceholder.render(.listIsEmpty)
                }
                emptyPlaceholder.isHidden = !emptyState
            }
        case .failed(_, let error):
            emptyPlaceholder.render(
                Placeholder.Config(
                    message: error.hint,
                    icon: error.iconName.flatMap(UIImage.init(systemName:))
                )
            )
            emptyPlaceholder.isHidden = false
        }
        setNeedsLayout()
    }
}

extension UserPreviewView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = .clear
    }
}

extension UserPreviewView {
    var sections: [Section] {
        [.main]
    }

    private func items(in section: Section) -> [UserPreviewState.SpendingPreview] {
        switch section {
        case .main:
            return state?.spenginds.value ?? []
        }
    }
}

// MARK: - DiffableDataSource Types

extension UserPreviewView {
    enum Section: Hashable {
        case main
    }
    typealias Cell = Spending.Identifier
    typealias DataSnapshot = NSDiffableDataSourceSnapshot<Section, Cell>
}

private class DataSource: UITableViewDiffableDataSource<UserPreviewView.Section, UserPreviewView.Cell> {}
