import Api
import DataTransferObjects
import PersistentStorage
import Foundation
import AsyncExtensions
import DataLayerDependencies
internal import Base
internal import DefaultNetworkingImplementation
internal import DefaultApiServiceImplementation
internal import DefaultApiImplementation
internal import PersistentStorageSQLite

struct Constants {
    static let apiEndpoint = "http://193.124.113.41:8082"
    static let appId = "com.rzmn.accountydev.app"
    static let appGroup = "group.\(appId)"
}

public final class DefaultAnonymousSession: AnonymousDataLayerSession {
    public let authenticator: AuthenticatedDataLayerSessionFactory
    public let api: ApiProtocol

    public init(taskFactory: TaskFactory) async throws {
        guard let permanentCacheDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroup
        ) else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        let taskFactory = DefaultTaskFactory()
        let networkServiceFactory = DefaultNetworkServiceFactory(
            logger: .shared.with(
                prefix: "[net] "
            ),
            session: .shared,
            endpoint: Endpoint(
                path: Constants.apiEndpoint
            )
        )
        let apiServiceFactory = DefaultApiServiceFactory(
            logger: .shared.with(
                prefix: "[api.s] "
            ),
            networkServiceFactory: networkServiceFactory,
            taskFactory: taskFactory
        )
        api = await DefaultApiFactory(
            service: apiServiceFactory.create(tokenRefresher: nil),
            taskFactory: taskFactory
        ).create()
        authenticator = DefaultAuthenticatedSessionFactory(
            api: api,
            taskFactory: taskFactory,
            apiServiceFactory: apiServiceFactory,
            persistencyFactory: try SQLitePersistencyFactory(
                logger: .shared.with(prefix: "[db] "),
                dbDirectory: permanentCacheDirectory,
                taskFactory: taskFactory
            )
        )
    }
}
