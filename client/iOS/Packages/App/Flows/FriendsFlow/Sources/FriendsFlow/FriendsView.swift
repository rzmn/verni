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

class FriendsView: View<FriendsFlow> {
    private let table = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.backgroundColor = .p.background
        t.backgroundView = UIView()
        t.separatorColor = .clear
        t.register(FriendCell.self, forCellReuseIdentifier: "\(FriendCell.self)")
        return t
    }()
    private lazy var cellProvider: DataSource.CellProvider = { [weak self] tableView, indexPath, _ in
        guard let self else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(FriendCell.self)") as! FriendCell
        let item = items(in: sections[indexPath.section].id)[indexPath.row]
        cell.render(user: item.user, balance: item.balance)
        cell.contentView.backgroundColor = .p.backgroundContent
        return cell
    }
    private lazy var dataSource = DataSource(
        tableView: table,
        cellProvider: cellProvider
    )
    private let emptyPlaceholder = Placeholder(config: .listIsEmpty)
    private var subscriptions = Set<AnyCancellable>()
    private var state: FriendsState {
        didSet {
            render(state: state)
        }
    }

    required init(model: FriendsFlow) {
        self.state = model.subject.value
        super.init(model: model)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupView() {
        backgroundColor = .p.background
        table.dataSource = dataSource
        table.delegate = self
        [table, emptyPlaceholder].forEach(addSubview)
        model.subject
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.state = state
                switch state.content {
                case .initial, .loading:
                    break
                case .loaded, .failed:
                    self.table.refreshControl?.endRefreshing()
                }
                self.render(state: state)
            }.store(in: &subscriptions)
        table.refreshControl = {
            let ptr = UIRefreshControl()
            ptr.addAction(weak(model, type(of: model).refresh), for: .valueChanged)
            return ptr
        }()
        render(state: state)
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

    private func render(state: FriendsState) {
        let snapshot = {
            var s = DataSnapshot()
            let sections = self.sections
            s.appendSections(sections)
            for section in sections {
                s.appendItems(items(in: section.id).map(\.user.id).map(Cell.init), toSection: section)
            }
            return s
        }()
        dataSource.defaultRowAnimation = .bottom
        dataSource.apply(snapshot, animatingDifferences: !table.isDragging && !table.isDecelerating)
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
                emptyPlaceholder.render(Placeholder.Config(message: error.hint, icon: error.iconName.flatMap(UIImage.init(systemName:))))
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
            emptyPlaceholder.render(Placeholder.Config(message: error.hint, icon: error.iconName.flatMap(UIImage.init(systemName:))))
            emptyPlaceholder.isHidden = false
        }
    }
}

extension FriendsView {

}

extension FriendsView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items(in: sections[indexPath.section].id)[indexPath.row]
        Task.detached { @MainActor in
            await self.model.openPreview(user: item.user)
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.font = .p.secondaryText
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = .clear
    }
}

extension FriendsView {
    var sections: [Section] {
        FriendsState.Section.order.filter {
            items(in: $0).isEmpty
        }.map(Section.init)
    }

    private func items(in section: FriendshipKind) -> [FriendsState.Item] {
        state.content.value.flatMap { content in
            content.sections.first {
                $0.id == .incoming
            }?.items
        } ?? []
    }
}

// MARK: - DiffableDataSource Types

extension FriendsView {
    struct Section: Hashable {
        let id: FriendshipKind
    }
    struct Cell: Hashable {
        let id: User.ID
    }

    typealias DataSnapshot = NSDiffableDataSourceSnapshot<Section, Cell>
}

private class DataSource: UITableViewDiffableDataSource<FriendsView.Section, FriendsView.Cell> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionIdentifier(for: section).flatMap {
            switch $0.id {
            case .friends:
                return "friend_list_section_friends".localized
            case .incoming:
                return "friend_list_section_incoming".localized
            case .pending:
                return "friend_list_section_outgoing".localized
            }
        }
    }
}
