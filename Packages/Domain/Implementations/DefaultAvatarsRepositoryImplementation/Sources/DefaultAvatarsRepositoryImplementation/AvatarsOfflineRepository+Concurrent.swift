import Foundation
import Domain
import Base
import AsyncExtensions

extension AvatarsOfflineRepository {
    func getConcurrent(taskFactory: TaskFactory, ids: [Avatar.Identifier]) async -> [Avatar.Identifier: Data] {
        await withTaskGroup(of: Optional<(id: Avatar.Identifier, data: Data)>.self) { group in
            for id in ids {
                group.addTask {
                    let data = await get(for: id)
                    if let data {
                        return (id: id, data: data)
                    } else {
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
}
