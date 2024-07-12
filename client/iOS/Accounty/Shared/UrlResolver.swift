import Domain
import Foundation

enum InternalUrl {
    static let scheme: String = "rzmnse"

    enum Users {
        case show(User.ID)
    }
    case users(Users)

    init?(string: String) {
        guard let url = URL(string: string) else {
            return nil
        }
        guard let scheme = url.scheme, scheme == Self.scheme else {
            return nil
        }
        guard let host = url.host() else {
            return nil
        }
        let components = url.pathComponents
        if host == "u", components.count == 2 {
            let uid = components[1]
            self = .users(.show(uid))
            return
        }
        return nil
    }
}

protocol UrlResolver {
    func resolve(url: InternalUrl) async
}
