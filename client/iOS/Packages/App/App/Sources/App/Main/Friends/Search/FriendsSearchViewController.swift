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
    private var subscriptions = Set<AnyCancellable>()
    private var content: Loadable<[User], String> {
        didSet {
            tableView.reloadData()
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
        tableView.separatorColor = .clear
        tableView.register(FriendCell.self, forCellReuseIdentifier: "\(FriendCell.self)")
        model.subject
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.content = state.content
            }
            .store(in: &subscriptions)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.isActive = true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = (content.value ?? [])[indexPath.row]
        searchController.isActive = false
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

extension FriendsSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else { return }
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
