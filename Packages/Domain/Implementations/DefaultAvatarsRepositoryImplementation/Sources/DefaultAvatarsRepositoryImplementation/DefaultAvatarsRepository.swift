import Domain
import Api
import Foundation
import Base
import Logging
internal import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultAvatarsRepository {
    private let api: ApiProtocol
    private let offlineRepository: AvatarsOfflineRepository
    private let offlineMutableRepository: AvatarsOfflineMutableRepository
    private let taskFactory: TaskFactory

    private var loadingIds = [Avatar.ID: Task<Result<Data, GeneralError>, Never>]()

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
        ids: [Avatar.ID],
        from loadingIds: [Avatar.ID: Task<Result<Data, GeneralError>, Never>]
    ) async -> [Avatar.ID: Data] {
        await withTaskGroup(of: Optional<(id: Avatar.ID, data: Data)>.self) { group in
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
            var loaded = [Avatar.ID: Data]()
            for await value in group {
                guard let value else {
                    continue
                }
                loaded[value.id] = value.data
            }
            return loaded
        }
    }

    func schedule(ids: [Avatar.ID]) {
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
                    if let data = avatar.base64Data.flatMap({ Data(base64Encoded: $0) }) {
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

    public func get(ids: [Avatar.ID]) async -> [Avatar.ID : Data] {
        let cached = await offlineRepository.getConcurrent(taskFactory: taskFactory, ids: ids)
        let alreadyRequested = await waitForScheduled(
            ids: ids.filter { cached[$0] == nil },
            from: loadingIds
        )
        let idsToLoad = ids.filter {
            cached[$0] == nil && alreadyRequested[$0] == nil
        }
        guard !idsToLoad.isEmpty else {
            return alreadyRequested.reduce(into: cached) { dict, kv in
                dict[kv.key] = kv.value
            }
        }
        schedule(ids: idsToLoad)
        let loaded = await waitForScheduled(
            ids: idsToLoad,
            from: loadingIds
        )
        return loaded.reduce(
            into: alreadyRequested.reduce(into: cached) { dict, kv in
                dict[kv.key] = kv.value
            }
        ) { dict, kv in
            dict[kv.key] = kv.value
        }
    }
}
