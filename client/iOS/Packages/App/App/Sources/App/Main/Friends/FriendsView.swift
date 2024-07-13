import UIKit
import Domain
import Combine
internal import DesignSystem

class FriendsView: UIView {
    private let model: FriendsModel
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
        cell.render(user: users(in: sections[indexPath.section])[indexPath.row])
        cell.contentView.backgroundColor = .p.backgroundContent
        return cell
    }
    private lazy var dataSource = DataSource(
        tableView: table,
        cellProvider: cellProvider
    )
    private let emptyPlaceholder = Placeholder(
        config: Placeholder.Config(
            message: "friend_list_empty_placeholder".localized,
            icon: UIImage(systemName: "person.crop.rectangle.badge.plus")
        )
    )
    private var subscriptions = Set<AnyCancellable>()
    private var state: FriendsState {
        didSet {
            handle(state: state)
        }
    }

    private func handle(state: FriendsState) {
        let snapshot = {
            var s = DataSnapshot()
            let sections = self.sections
            s.appendSections(sections)
            for section in sections {
                s.appendItems(users(in: section).map(\.id).map(Cell.init), toSection: section)
            }
            return s
        }()
        dataSource.defaultRowAnimation = .bottom
        dataSource.apply(snapshot, animatingDifferences: !table.isDragging && !table.isDecelerating)
        switch state.content {
        case .initial:
            emptyPlaceholder.isHidden = true
        case .loaded:
            emptyPlaceholder.isHidden = !sections.isEmpty
        case .loading(let previous):
            if previous.error != nil {
                emptyPlaceholder.isHidden = true
            } else if case .initial = previous {
                emptyPlaceholder.isHidden = true
            } else {
                emptyPlaceholder.isHidden = !sections.isEmpty
            }
        case .failed:
            emptyPlaceholder.isHidden = true
        }
    }

    init(model: FriendsModel) {
        self.model = model
        state = model.subject.value
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
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
            }.store(in: &subscriptions)
        table.refreshControl = {
            let ptr = UIRefreshControl()
            ptr.addAction({ [weak self] in
                await self?.model.refresh()
            }, for: .valueChanged)
            return ptr
        }()
        emptyPlaceholder.addAction({ [weak self] in
            await self?.model.searchForFriends()
        }, for: .touchUpInside)
        handle(state: state)
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
}

extension FriendsView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users(in: sections[indexPath.section])[indexPath.row]
        Task {
            await self.model.showUser(user: user)
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
        [.incoming, .outgoing, .friends].filter {
            !users(in: $0).isEmpty
        }
    }

    private func users(in section: Section) -> [User] {
        switch section {
        case .incoming:
            return state.content.value?.upcomingRequests ?? []
        case .friends:
            return state.content.value?.friends ?? []
        case .outgoing:
            return state.content.value?.pendingRequests ?? []
        }
    }
}

// MARK: - DiffableDataSource Types

extension FriendsView {
    enum Section: CaseIterable {
        case incoming
        case friends
        case outgoing
    }
    struct Cell: Hashable {
        let id: User.ID
    }

    typealias DataSnapshot = NSDiffableDataSourceSnapshot<Section, Cell>
}

private class DataSource: UITableViewDiffableDataSource<FriendsView.Section, FriendsView.Cell> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionIdentifier(for: section).flatMap {
            switch $0 {
            case .friends:
                return "friend_list_section_friends".localized
            case .incoming:
                return "friend_list_section_incoming".localized
            case .outgoing:
                return "friend_list_section_outgoing".localized
            }
        }
    }
}
