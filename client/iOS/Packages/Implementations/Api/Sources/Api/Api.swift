import ApiService
import Networking
import Combine
import Base

fileprivate protocol _Parameters: Encodable, CompactDescription {}

public class Api {
    private enum RefreshTokenError: Error {
        case internalError
    }

    public let friendsUpdated = PassthroughSubject<Void, Never>()
    public let spendingsUpdated = PassthroughSubject<Void, Never>()
    private let service: ApiService
    private var subscriptions = Set<AnyCancellable>()

    public init(service: ApiService, polling: ApiPolling? = nil) {
        self.service = service
        polling?.friends
            .sink {
                self.friendsUpdated.send(())
                self.spendingsUpdated.send(())
            }
            .store(in: &subscriptions)
    }
}

// MARK: Types

extension Api {
    typealias ApiResultInternal<T: DecodableResponse> = Result<ApiResponseDto<T>, ApiServiceError>
}

// MARK: Auth

extension Api {
    public func refresh(token: String) async -> ApiResult<ApiAuthTokenDto> {
        struct RequestParameters: _Parameters {
            let refreshToken: String
        }
        let result: ApiResultInternal<SingleValueResponse<ApiAuthTokenDto>> = await run(
            method: Method.Auth.refresh,
            parameters: RequestParameters(
                refreshToken: token
            )
        )
        return mapApiResponse(result).map(\.value)
    }

    public func login(credentials: CredentialsDto) async -> ApiResult<ApiAuthTokenDto> {
        struct RequestParameters: _Parameters {
            let credentials: CredentialsDto
        }
        let result: ApiResultInternal<SingleValueResponse<ApiAuthTokenDto>> = await run(
            method: Method.Auth.login,
            parameters: RequestParameters(
                credentials: credentials
            )
        )
        return mapApiResponse(result).map(\.value)
    }

    public func signup(credentials: CredentialsDto) async -> ApiResult<ApiAuthTokenDto> {
        struct RequestParameters: _Parameters {
            let credentials: CredentialsDto
        }
        let result: ApiResultInternal<SingleValueResponse<ApiAuthTokenDto>> = await run(
            method: Method.Auth.signup,
            parameters: RequestParameters(
                credentials: credentials
            )
        )
        return mapApiResponse(result).map(\.value)
    }
}

// MARK: Users

extension Api {
    public func getMyInfo() async -> ApiResult<UserDto> {
        let result: ApiResultInternal<SingleValueResponse<UserDto>> = await run(method: Method.Users.getMyInfo)
        return mapApiResponse(result).map(\.value)
    }

    public func getUsers(uids: [UserDto.ID]) async -> ApiResult<[UserDto]> {
        struct RequestParameters: _Parameters {
            let ids: [UserDto.ID]
        }
        let result: ApiResultInternal<SingleValueResponse<[UserDto]>> = await run(
            method: Method.Users.get,
            parameters: RequestParameters(
                ids: uids
            )
        )
        return mapApiResponse(result).map(\.value)
    }

    public func searchUsers(query: String) async -> ApiResult<[UserDto]> {
        struct RequestParameters: _Parameters {
            let query: String
        }
        let result: ApiResultInternal<SingleValueResponse<[UserDto]>> = await run(
            method: Method.Users.search,
            parameters: RequestParameters(
                query: query
            )
        )
        return mapApiResponse(result).map(\.value)
    }
}

// MARK: Friends

extension Api {
    public func getFriends(kinds: [FriendshipKindDto]) async -> ApiResult<[FriendshipKindDto: [UserDto.ID]]> {
        struct RequestParameters: _Parameters {
            let statuses: [Int]
        }
        let result: ApiResultInternal<SingleValueResponse<[Int: [UserDto.ID]]>> = await run(
            method: Method.Friends.get,
            parameters: RequestParameters(
                statuses: kinds.map(\.rawValue)
            )
        )
        return mapApiResponse(result)
            .map(\.value)
            .map { dict in
                Dictionary(
                    uniqueKeysWithValues: dict.compactMap { kv in
                        guard let key = FriendshipKindDto(rawValue: kv.key) else {
                            return nil
                        }
                        return (key, kv.value)
                    }
                )
            }
    }

    public func acceptFriendRequest(from uid: UserDto.ID) async -> ApiResult<Void> {
        struct RequestParameters: _Parameters {
            let sender: String
        }
        let result: ApiResultInternal<EmptyResponse> = await run(
            method: Method.Friends.acceptRequest,
            parameters: RequestParameters(
                sender: uid
            )
        )
        if case .success = result {
            friendsUpdated.send(())
        }
        return mapApiResponse(result)
    }

    public func rejectFriendRequest(from uid: UserDto.ID) async -> ApiResult<Void> {
        struct RequestParameters: _Parameters {
            let sender: String
        }
        let result: ApiResultInternal<EmptyResponse> = await run(
            method: Method.Friends.rejectRequest,
            parameters: RequestParameters(
                sender: uid
            )
        )
        if case .success = result {
            friendsUpdated.send(())
        }
        return mapApiResponse(result)
    }

    public func sendFriendRequest(to uid: UserDto.ID) async -> ApiResult<Void> {
        struct RequestParameters: _Parameters {
            let target: String
        }
        let result: ApiResultInternal<EmptyResponse> = await run(
            method: Method.Friends.sendRequest,
            parameters: RequestParameters(
                target: uid
            )
        )
        if case .success = result {
            friendsUpdated.send(())
        }
        return mapApiResponse(result)
    }

    public func rollbackFriendRequest(to uid: UserDto.ID) async -> ApiResult<Void> {
        struct RequestParameters: _Parameters {
            let target: String
        }
        let result: ApiResultInternal<EmptyResponse> = await run(
            method: Method.Friends.rollbackRequest,
            parameters: RequestParameters(
                target: uid
            )
        )
        if case .success = result {
            friendsUpdated.send(())
        }
        return mapApiResponse(result)
    }

    public func unfriend(uid: UserDto.ID) async -> ApiResult<Void> {
        struct RequestParameters: _Parameters {
            let target: String
        }
        let result: ApiResultInternal<EmptyResponse> = await run(
            method: Method.Friends.unfriend,
            parameters: RequestParameters(
                target: uid
            )
        )
        if case .success = result {
            friendsUpdated.send(())
        }
        return mapApiResponse(result)
    }

    public func createDeal(deal: DealDto) async -> ApiResult<[SpendingsPreviewDto]> {
        struct RequestParameters: _Parameters {
            let deal: DealDto
        }
        let result: ApiResultInternal<SingleValueResponse<[SpendingsPreviewDto]>> = await run(
            method: Method.Spendings.createDeal,
            parameters: RequestParameters(
                deal: deal
            )
        )
        return mapApiResponse(result).map(\.value)
    }

    public func deleteDeal(id: DealDto.ID) async -> ApiResult<[SpendingsPreviewDto]> {
        struct RequestParameters: _Parameters {
            let dealId: DealDto.ID
        }
        let result: ApiResultInternal<SingleValueResponse<[SpendingsPreviewDto]>> = await run(
            method: Method.Spendings.deleteDeal,
            parameters: RequestParameters(
                dealId: id
            )
        )
        return mapApiResponse(result).map(\.value)
    }

    public func getCounterparties() async -> ApiResult<[SpendingsPreviewDto]> {
        let result: ApiResultInternal<SingleValueResponse<[SpendingsPreviewDto]>> = await run(
            method: Method.Spendings.getCounterparties
        )
        return mapApiResponse(result).map(\.value)
    }

    public func getDeals(counterparty: UserDto.ID) async -> ApiResult<[IdentifiableDealDto]> {
        struct RequestParameters: _Parameters {
            let counterparty: UserDto.ID
        }
        let result: ApiResultInternal<SingleValueResponse<[IdentifiableDealDto]>> = await run(
            method: Method.Spendings.getCounterparties,
            parameters: RequestParameters(
                counterparty: counterparty
            )
        )
        return mapApiResponse(result).map(\.value)
    }
}

// MARK: - Private

private extension Api {
    func run<RequestResponse: Decodable>(
        method: ApiMethod
    ) async -> ApiResultInternal<RequestResponse> {
        await service.run(
            request: Request(
                path: method.path,
                headers: [:],
                httpMethod: method.method
            )
        )
    }

    func run<RequestResponse: Decodable, RequestParameters: Encodable>(
        method: ApiMethod,
        parameters: RequestParameters
    ) async -> ApiResultInternal<RequestResponse> {
        await service.run(
            request: RequestWithParameters(
                request: Request(
                    path: method.path,
                    headers: [:],
                    httpMethod: method.method
                ),
                parameters: parameters
            )
        )
    }

    private func mapApiResponse(_ response: ApiResultInternal<EmptyResponse>) -> ApiResult<Void> {
        let response: ApiResult<EmptyResponse> = mapApiResponse(response)
        return response.map { _ in () }
    }

    private func mapApiResponse<T>(_ response: ApiResultInternal<T>) -> ApiResult<T> {
        switch response {
        case .success(let response):
            switch response {
            case .success(let response):
                return .success(response)
            case .failure(let error):
                return .failure(.api(error.code, description: error.description))
            }
        case .failure(let error):
            switch error {
            case .noConnection(let error):
                return .failure(.noConnection(error))
            case .decodingFailed(let error):
                return .failure(.internalError(error))
            case .internalError(let error):
                return .failure(.internalError(error))
            case .unauthorized:
                return .failure(.api(.tokenExpired, description: nil))
            }
        }
    }
}
