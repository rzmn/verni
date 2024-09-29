import UIKit
import Combine
import Domain
import AppBase
internal import DesignSystem

private extension Placeholder.Config {
    static var listIsEmpty: Self {
        Self(
            message: "friend_list_empty_placeholder".localized,
            icon: UIImage(systemName: "person.crop.rectangle.badge.plus")
        )
    }
}

class PickCounterpartyView: UIKitBasedView<PickCounterpartyViewActions> {
    private let table = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .palette.background
        table.backgroundView = UIView()
        table.separatorColor = .clear
        table.register(UserCell.self)
        return table
    }()
    private lazy var cellProvider: DataSource.CellProvider = { [unowned self] tableView, indexPath, _ in
        let cell = tableView.dequeue(UserCell.self, at: indexPath)
        let item = items(in: sections[indexPath.section])[indexPath.row]
        cell.render(user: item)
        cell.contentView.backgroundColor = .palette.backgroundContent
        return cell
    }
    private lazy var dataSource = DataSource(
        tableView: table,
        cellProvider: cellProvider
    )
    private let emptyPlaceholder = Placeholder(config: .listIsEmpty)
    private var subscriptions = Set<AnyCancellable>()
    private var state: PickCounterpartyState? {
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
            .map { $0 as PickCounterpartyState? }
            .assign(to: \.state, on: self)
            .store(in: &subscriptions)
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

    private func render(state: PickCounterpartyState, animated: Bool) {
        switch state.content {
        case .initial, .loading:
            break
        case .loaded, .failed:
            self.table.refreshControl?.endRefreshing()
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

extension PickCounterpartyView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items(in: sections[indexPath.section])[indexPath.row]
        model.handle(.onPickounterpartyTap(item))
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = .clear
    }
}

extension PickCounterpartyView {
    var sections: [Section] {
        state?.content.value?.map(\.kind) ?? []
    }

    private func items(in section: Section) -> [User] {
        state?.content.value.flatMap { content in
            content.first {
                $0.kind == section
            }
        }.map(\.items) ?? []
    }
}

// MARK: - DiffableDataSource Types

extension PickCounterpartyView {
    typealias Section = PickCounterpartyState.Section.Kind
    typealias Cell = User.Identifier

    typealias DataSnapshot = NSDiffableDataSourceSnapshot<Section, Cell>
}

private class DataSource: UITableViewDiffableDataSource<PickCounterpartyView.Section, PickCounterpartyView.Cell> {}
