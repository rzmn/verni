import UIKit

extension UITableView {
    public func dequeue<T: UITableViewCell>(_ type: T.Type, at indexPath: IndexPath) -> T {
        let identifier = String(describing: type)
        // swiftlint:disable:next force_cast
        return dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! T
    }

    public func register<T: UITableViewCell>(_ type: T.Type) {
        let identifier = String(describing: type)
        register(type, forCellReuseIdentifier: identifier)
    }
}

extension UITableView {
    public func dequeue<T: UITableViewHeaderFooterView>(_ type: T.Type) -> T {
        let identifier = String(describing: type)
        // swiftlint:disable:next force_cast
        return dequeueReusableHeaderFooterView(withIdentifier: identifier) as! T
    }

    public func register<T: UITableViewHeaderFooterView>(_ type: T.Type) {
        let identifier = String(describing: type)
        register(type, forHeaderFooterViewReuseIdentifier: identifier)
    }
}

extension UITableView {
    public func scrollToTop(animated: Bool) {
        let sel = NSSelectorFromString("vkm_scrollToTopIfPossible:")
        if responds(to: sel) {
            perform(sel, with: animated)
        } else {
            setContentOffset(.zero, animated: animated)
        }
    }
}
