import AppBase
import UIKit
import Domain
import Combine
internal import Base
internal import DesignSystem

private extension Placeholder.Config {
    static var listIsEmpty: Self {
        Self(
            message: "friend_list_empty_placeholder".localized,
            icon: UIImage(systemName: "person.crop.rectangle.badge.plus")
        )
    }
}

class FriendsView: View<FriendsViewActions> {
    private let table = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .palette.background
        table.backgroundView = UIView()
        table.separatorColor = .clear
        table.register(FriendCell.self)
        return table
    }()
    private lazy var cellProvider: DataSource.CellProvider = { [unowned self] tableView, indexPath, _ in
        let cell = tableView.dequeue(FriendCell.self, at: indexPath)
        let item = items(in: sections[indexPath.section])[indexPath.row]
        cell.render(item: item)
        cell.contentView.backgroundColor = .palette.backgroundContent
        return cell
    }
    private lazy var dataSource = DataSource(
        tableView: table,
        cellProvider: cellProvider
    )
    private let emptyPlaceholder = Placeholder(config: .listIsEmpty)
    private var subscriptions = Set<AnyCancellable>()
    private var state: FriendsState? {
        didSet {
            guard let state else { return }
            render(state: state, animated: oldValue != nil)
        }
    }

    override func setupView() {
        backgroundColor = .palette.background
        table.dataSource = dataSource
        table.delegate = self
        for view in [table, emptyPlaceholder] {
            addSubview(view)
        }
        dataSource.defaultRowAnimation = .bottom
        model.state
            .map { $0 as FriendsState? }
            .assign(to: \.state, on: self)
            .store(in: &subscriptions)
        table.refreshControl = {
            let ptr = UIRefreshControl()
            ptr.addAction({ [model] in
                model.handle(.onPulledToRefresh)
            }, for: .valueChanged)
            return ptr
        }()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        table.frame = bounds
        let placeholderSize = emptyPlaceholder.sizeThatFits(bounds.size)
        emptyPlaceholder.frame = CGRect(
            x: bounds.midX - placeholderSize.width / 2,
            y: bounds.midY - placeholderSize.height / 2,
            width: placeholderSize.width,
            height: placeholderSize.height
        )
    }

    private func render(state: FriendsState, animated: Bool) {
        switch state.content {
        case .initial, .loading:
            break
        case .loaded, .failed:
            table.refreshControl?.endRefreshing()
        }
        dataSource.apply(.snapshot(sections: sections, cells: { section in
            items(in: section).map(\.id)
        }), animatingDifferences: !table.isDragging && !table.isDecelerating)
        switch state.content {
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
    }
}

extension FriendsView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items(in: sections[indexPath.section])[indexPath.row]
        model.handle(.onUserSelected(item.data.user))
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.font = .palette.secondaryText
    }
}

extension FriendsView {
    var sections: [Section] {
        state?.content.value?.sections.map(\.id) ?? []
    }

    private func items(in section: FriendshipKind) -> [FriendsState.Item] {
        state?.content.value.flatMap { content in
            content.sections.first {
                $0.id == section
            }?.items
        } ?? []
    }
}

// MARK: - DiffableDataSource Types

extension FriendsView {
    typealias Section = FriendshipKind
    typealias Cell = User.Identifier

    typealias DataSnapshot = NSDiffableDataSourceSnapshot<Section, Cell>
}

private class DataSource: UITableViewDiffableDataSource<FriendsView.Section, FriendsView.Cell> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionIdentifier(for: section).flatMap {
            switch $0 {
            case .friends:
                return "friend_list_section_friends".localized
            case .subscriber:
                return "friend_list_section_incoming".localized
            case .subscription:
                return "friend_list_section_outgoing".localized
            }
        }
    }
}
