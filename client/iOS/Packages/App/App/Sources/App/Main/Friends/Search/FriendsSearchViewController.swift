import UIKit
import Combine
import Domain
import DesignSystem

class FriendsSearchViewController: UITableViewController {
    private let model: FriendsSearchModel
    private lazy var searchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.delegate = self
        search.searchBar.placeholder = "friends_search_searchbar_placeholder".localized
        search.searchBar.searchTextField.font = .p.placeholder
        search.hidesNavigationBarDuringPresentation = false
        search.searchBar.backgroundImage = UIImage()
        search.searchBar.backgroundColor = .p.background
        search.searchBar.barTintColor = .p.background
        search.searchBar.tintColor = .p.primary
        search.searchBar.searchTextField.autocapitalizationType = .none
        return search
    }()
    private lazy var cellProvider: DataSource.CellProvider = { [weak self] tableView, indexPath, _ in
        guard let self else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(FriendCell.self)") as! FriendCell
        cell.render(user: users(in: sections[indexPath.section])[indexPath.row])
        cell.contentView.backgroundColor = .p.backgroundContent
        return cell
    }
    private lazy var dataSource = DataSource(
        tableView: tableView,
        cellProvider: cellProvider
    )
    private let emptyPlaceholder = RefreshPlaceholder(
        config: RefreshPlaceholder.Config(
            message: "friend_search_empty_placeholder".localized,
            icon: UIImage(systemName: "eyes")
        )
    )
    private var subscriptions = Set<AnyCancellable>()
    private var content: Loadable<[User], String> {
        didSet {
            handle(state: content)
        }
    }

    private func handle(state: Loadable<[User], String>) {
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
        dataSource.apply(snapshot, animatingDifferences: !tableView.isDragging && !tableView.isDecelerating)
        switch state {
        case .initial:
            emptyPlaceholder.isHidden = false
        case .loaded:
            emptyPlaceholder.isHidden = !sections.isEmpty
        case .loading(let previous):
            if previous.error != nil {
                emptyPlaceholder.isHidden = true
            } else if case .initial = previous {
                emptyPlaceholder.isHidden = false
            } else {
                emptyPlaceholder.isHidden = !sections.isEmpty
            }
        case .failed:
            emptyPlaceholder.isHidden = true
        }
    }

    init(model: FriendsSearchModel) {
        self.model = model
        self.content = model.subject.value.content
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "friends_search_title".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        tableView.backgroundColor = .p.background
        tableView.backgroundView = UIView()
        tableView.dataSource = dataSource
        tableView.separatorColor = .clear
        tableView.register(FriendCell.self, forCellReuseIdentifier: "\(FriendCell.self)")
        [emptyPlaceholder].forEach(view.addSubview)
        model.subject
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.content = state.content
            }
            .store(in: &subscriptions)
        handle(state: content)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let placeholderSize = emptyPlaceholder.sizeThatFits(view.bounds.size)
        emptyPlaceholder.frame = CGRect(
            x: view.bounds.midX - placeholderSize.width / 2,
            y: 88,
            width: placeholderSize.width,
            height: placeholderSize.height
        )
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = (content.value ?? [])[indexPath.row]
        Task {
            await self.model.open(user: user)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (content.value ?? []).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(FriendCell.self)") as! FriendCell
        let user = (content.value ?? [])[indexPath.row]
        cell.render(user: user)
        cell.contentView.backgroundColor = .p.backgroundContent
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = .clear
    }
}

// MARK: - DiffableDataSource Types

extension FriendsSearchViewController {
    enum Section: CaseIterable {
        case main
    }
    struct Cell: Hashable {
        let id: User.ID
    }

    typealias DataSnapshot = NSDiffableDataSourceSnapshot<Section, Cell>
    typealias DataSource = UITableViewDiffableDataSource<Section, Cell>

    var sections: [Section] {
        [.main].filter {
            !users(in: $0).isEmpty
        }
    }

    private func users(in section: Section) -> [User] {
        switch section {
        case .main:
            return content.value ?? []
        }
    }
}

extension FriendsSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        Task {
            await self.model.search(query: query)
        }
    }
}

extension FriendsSearchViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }
}
