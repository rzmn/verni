import UIKit

public extension NSDiffableDataSourceSnapshot {
    static func snapshot(
        sections: [SectionIdentifierType],
        cells: (SectionIdentifierType) -> [ItemIdentifierType]
    ) -> Self {
        var s = Self()
        let sections = sections
        s.appendSections(sections)
        for section in sections {
            s.appendItems(cells(section), toSection: section)
        }
        return s
    }
}
