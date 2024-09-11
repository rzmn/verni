import Domain
import Api
import Foundation
import Base
internal import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultAvatarsRepository {
    private let api: ApiProtocol
    private let offlineRepository: AvatarsOfflineRepository
    private let taskFactory: TaskFactory

    private var loadingIds = [Avatar.ID: Task<Result<Data, GeneralError>, Never>]()
    private var loadingIdsContinuation = [Avatar.ID: CheckedContinuation<Result<Data, GeneralError>, Never>]()

    public init(api: ApiProtocol, taskFactory: TaskFactory) {
        self.api = api
        self.taskFactory = taskFactory
        offlineRepository = AvatarsOfflineRepository()
    }
}

extension DefaultAvatarsRepository: AvatarsRepository {
    public func get(ids: [Avatar.ID]) async throws(GeneralError) -> [Avatar.ID : Data] {
        let cached = (await ids.concurrentMap(taskFactory: taskFactory) { id in
            let data = await self.offlineRepository.getData(for: id)
            if let data {
                return (id, data)
            } else {
                return nil
            }
        } as [(Avatar.ID, Data)?]).compactMap { $0 }

        let currentlyLoading = ids.compactMap { id -> (Avatar.ID, Task<Result<Data, GeneralError>, Never>)? in
            guard let task = loadingIds[id] else {
                return nil
            }
            return (id, task)
        }
        let successfullyLoaded = (await currentlyLoading.concurrentMap(taskFactory: taskFactory) { (id, task) in
            let result = await task.result
            guard case .success(let taskResult) = result, case .success(let data) = taskResult else {
                return nil
            }
            return (id, data)
        } as [(Avatar.ID, Data)?]).compactMap { $0 }

        currentlyLoading.map(\.0).forEach {
            loadingIds.removeValue(forKey: $0)
        }

        let cachedSet = Set([cached.map(\.0), successfullyLoaded.map(\.0)].flatMap { $0 })
        let idsToLoad = ids.filter { !cachedSet.contains($0) }

        for id in idsToLoad {
            loadingIds[id] = taskFactory.task {
                await withCheckedContinuation {
                    self.loadingIdsContinuation[id] = $0
                }
            }
        }

        guard idsToLoad.count > 0 else {
            return [cached, successfullyLoaded]
                .flatMap { $0 }
                .reduce(
                    into: [:], { dict, kv in
                        dict[kv.0] = kv.1
                    }
                )
        }
        do {
            let values = try await api.run(method: Avatars.Get(ids: idsToLoad))
            idsToLoad.forEach { id in
                if let avatar = values[id] {
                    if let data = avatar.base64Data.flatMap({ Data(base64Encoded: $0) }) {
                        self.loadingIdsContinuation[id]?.resume(returning: .success(data))
                    } else {
                        self.loadingIdsContinuation[id]?.resume(returning: .failure(.other(AvatarsRepositoryError.hasNoData)))
                    }
                } else {
                    self.loadingIdsContinuation[id]?.resume(returning: .failure(.other(AvatarsRepositoryError.idDoesNotExist)))
                }
                self.loadingIdsContinuation[id] = nil
            }
            var dict = [Avatar.ID: Data]()
            cached.forEach {
                dict[$0.0] = $0.1
            }
            successfullyLoaded.forEach {
                dict[$0.0] = $0.1
            }
            values.compactMapValues { value in
                guard let base64 = value.base64Data else {
                    return nil
                }
                return Data(base64Encoded: base64)
            }.forEach {
                dict[$0.key] = $0.value
            }
            _ = await values.concurrentMap(taskFactory: taskFactory) { value in
                guard let base64 = value.value.base64Data else {
                    return
                }
                guard let data = Data(base64Encoded: base64) else {
                    return
                }
                return await self.offlineRepository.store(data: data, for: value.key)
            }
            return dict
        } catch {
            let error = GeneralError(apiError: error)
            idsToLoad.forEach { id in
                self.loadingIdsContinuation[id]?.resume(returning: .failure(error))
                self.loadingIdsContinuation[id] = nil
            }
            throw error
        }
    }
}
