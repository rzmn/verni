import Networking

protocol ApiMethod {
    var path: String { get }
    var method: HttpMethod { get }
}

extension Api {
    enum Method {
        enum Auth: ApiMethod {
            case login
            case signup
            case refresh

            var path: String {
                switch self {
                case .login:
                    return "/auth/login"
                case .refresh:
                    return "/auth/refresh"
                case .signup:
                    return "/auth/signup"
                }
            }

            var method: HttpMethod {
                switch self {
                case .login, .refresh, .signup:
                    return .put
                }
            }
        }

        enum Friends: ApiMethod {
            case acceptRequest
            case get
            case sendRequest
            case rollbackRequest
            case rejectRequest
            case unfriend

            var path: String {
                switch self {
                case .acceptRequest:
                    return "/friends/acceptRequest"
                case .get:
                    return "/friends/get"
                case .sendRequest:
                    return "/friends/sendRequest"
                case .unfriend:
                    return "/friends/unfriend"
                case .rejectRequest:
                    return "/friends/rejectRequest"
                case .rollbackRequest:
                    return "/friends/rollbackRequest"
                }
            }

            var method: HttpMethod {
                switch self {
                case .sendRequest, .acceptRequest, .unfriend, .rejectRequest, .rollbackRequest:
                    return .post
                case .get:
                    return .get
                }
            }
        }

        enum Users: ApiMethod {
            case getMyInfo
            case get
            case search

            var path: String {
                switch self {
                case .getMyInfo:
                    return "/users/getMyInfo"
                case .get:
                    return "/users/get"
                case .search:
                    return "/users/search"
                }
            }

            var method: HttpMethod {
                switch self {
                case .getMyInfo, .get, .search:
                    return .get
                }
            }
        }
    }
}
