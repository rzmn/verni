import Foundation
import AsyncExtensions
internal import Api
internal import Base
internal import ApiService
internal import Networking
internal import PersistentStorage
internal import DefaultApiServiceImplementation
internal import DefaultNetworkingImplementation
internal import DefaultApiImplementation
internal import PersistentStorageSQLite

final class DataLayerDependencies: Sendable {
    let anonymousApi: ApiProtocol
    let apiServiceFactory: ApiServiceFactory
    let persistencyFactory: PersistencyFactory
    private let networkServiceFactory: NetworkServiceFactory
    private let apiEndpoint = "http://193.124.113.41:8082"
    private let taskFactory: TaskFactory

    init(taskFactory: TaskFactory) async throws {
        guard let permanentCacheDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.rzmn.accountydev.app"
        ) else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        self.taskFactory = taskFactory
        networkServiceFactory = DefaultNetworkServiceFactory(
            logger: .shared.with(
                prefix: "[net] "
            ),
            session: .shared,
            endpoint: Endpoint(
                path: apiEndpoint
            )
        )
        apiServiceFactory = DefaultApiServiceFactory(
            logger: .shared.with(
                prefix: "[api.s] "
            ),
            networkServiceFactory: networkServiceFactory,
            taskFactory: taskFactory
        )
        persistencyFactory = try SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[db] "),
            dbDirectory: permanentCacheDirectory,
            taskFactory: taskFactory
        )
        anonymousApi = await DefaultApiFactory(
            service: apiServiceFactory.create(tokenRefresher: nil),
            taskFactory: taskFactory
        ).create()
    }

    func apiFactory(refresher: TokenRefresher) async -> ApiFactory {
        await DefaultApiFactory(
            service: apiServiceFactory.create(
                tokenRefresher: refresher
            ),
            taskFactory: taskFactory
        )
    }
}
