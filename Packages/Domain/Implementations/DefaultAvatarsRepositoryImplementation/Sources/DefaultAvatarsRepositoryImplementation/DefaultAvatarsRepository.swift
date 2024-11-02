import Domain
import Api
import Foundation
import Base
import Logging
import AsyncExtensions
internal import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultAvatarsRepository {
    private let api: ApiProtocol
    private let offlineRepository: AvatarsOfflineRepository
    private let offlineMutableRepository: AvatarsOfflineMutableRepository
    private let taskFactory: TaskFactory

    private var loadingIds = [Avatar.Identifier: Task<Result<Data, GeneralError>, Never>]()

    public init(
        api: ApiProtocol,
        taskFactory: TaskFactory,
        offlineRepository: AvatarsOfflineRepository,
        offlineMutableRepository: AvatarsOfflineMutableRepository,
        logger: Logger
    ) {
        self.api = api
        self.offlineRepository = offlineRepository
        self.offlineMutableRepository = offlineMutableRepository
        self.taskFactory = taskFactory
    }
}

extension DefaultAvatarsRepository: AvatarsRepository {
    func waitForScheduled(
        ids: [Avatar.Identifier],
        from loadingIds: [Avatar.Identifier: Task<Result<Data, GeneralError>, Never>]
    ) async -> [Avatar.Identifier: Data] {
        await withTaskGroup(of: Optional<(id: Avatar.Identifier, data: Data)>.self) { group in
            for id in ids {
                guard let task = loadingIds[id] else {
                    continue
                }
                group.addTask {
                    let result = await task.value
                    switch result {
                    case .success(let data):
                        return (id: id, data: data)
                    case .failure:
                        return nil
                    }
                }
            }
            var loaded = [Avatar.Identifier: Data]()
            for await value in group {
                guard let value else {
                    continue
                }
                loaded[value.id] = value.data
            }
            return loaded
        }
    }

    func schedule(ids: [Avatar.Identifier]) {
        let fetchTask = taskFactory.task { [api] in
            try await api.run(method: Avatars.Get(ids: ids))
        }
        ids.forEach { [offlineMutableRepository] id in
            loadingIds[id] = taskFactory.task {
                let fetchResult: Avatars.Get.Response
                do {
                    fetchResult = try await fetchTask.value
                } catch {
                    if let error = error as? GeneralError {
                        return .failure(error)
                    } else {
                        assertionFailure()
                        return .failure(.other(error))
                    }
                }
                if let avatar = fetchResult[id] {
                    if let data = Data(base64Encoded: avatar.base64) {
                        await offlineMutableRepository.store(data: data, for: id)
                        return .success(data)
                    } else {
                        return .failure(.other(AvatarsRepositoryError.hasNoData))
                    }
                } else {
                    return .failure(.other(AvatarsRepositoryError.idDoesNotExist))
                }
            }
        }
    }

    public func get(ids: [Avatar.Identifier]) async -> [Avatar.Identifier: Data] {
        let cached = await offlineRepository.getConcurrent(taskFactory: taskFactory, ids: ids)
        let alreadyRequested = await waitForScheduled(
            ids: ids.filter { cached[$0] == nil },
            from: loadingIds
        )
        let idsToLoad = ids.filter {
            cached[$0] == nil && alreadyRequested[$0] == nil
        }
        guard !idsToLoad.isEmpty else {
            return alreadyRequested.reduce(into: cached) { dict, element in
                let (key, value) = element
                dict[key] = value
            }
        }
        schedule(ids: idsToLoad)
        let loaded = await waitForScheduled(
            ids: idsToLoad,
            from: loadingIds
        )
        return loaded.reduce(
            into: alreadyRequested.reduce(into: cached) { dict, element in
                let (key, value) = element
                dict[key] = value
            }
        ) { dict, element in
            let (key, value) = element
            dict[key] = value
        }
    }
}
