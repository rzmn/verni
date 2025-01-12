import Foundation

public enum AppUrl: Sendable {
    private var scheme: String {
        "verni"
    }

    public enum Users: Sendable {
        case show(id: String)
    }
    case users(Users)

    public var url: String {
        switch self {
        case .users(let action):
            switch action {
            case .show(let id):
                return "\(scheme)://u/\(id)"
            }
        }
    }

    public init?(string: String) {
        guard let url = URL(string: string) else {
            return nil
        }
        guard let scheme = url.scheme, scheme == scheme else {
            return nil
        }
        guard let host = url.host() else {
            return nil
        }
        let components = url.pathComponents
        if host == "u", components.count == 2 {
            let uid = components[1]
            self = .users(.show(id: uid))
            return
        }
        return nil
    }
}
