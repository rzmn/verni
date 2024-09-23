import UIKit

public extension NSDiffableDataSourceSnapshot {
    static func snapshot(
        sections: [SectionIdentifierType],
        cells: (SectionIdentifierType) -> [ItemIdentifierType]
    ) -> Self {
        var snapshot = Self()
        let sections = sections
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(cells(section), toSection: section)
        }
        return snapshot
    }
}
