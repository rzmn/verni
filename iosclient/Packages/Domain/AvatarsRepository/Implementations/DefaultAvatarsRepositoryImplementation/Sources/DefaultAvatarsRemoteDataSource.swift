import Entities
import AvatarsRepository
import Api
import Filesystem
import Foundation
import Logging
import AsyncExtensions
internal import Convenience

public actor DefaultAvatarsRemoteDataSource: Sendable {
    public let logger: Logger
    private let cache: Cache?
    private let api: APIProtocol
    private let taskFactory: TaskFactory
    enum Element {
        case fetching(query: Task<[Image.Identifier: Image], Never>)
        case fetched(Image)
    }
    private var elements: [Image.Identifier: Element]
    
    public init(
        logger: Logger,
        fileManager: Filesystem.FileManager,
        taskFactory: TaskFactory,
        api: APIProtocol
    ) {
        self.logger = logger
        self.api = api
        self.taskFactory = taskFactory
        self.elements = [:]
        do {
            cache = try Cache(
                fileManager: fileManager,
                logger: logger
            )
        } catch {
            cache = nil
            logE { "failed to create avatars cache error: \(error)" }
        }
    }
}

extension DefaultAvatarsRemoteDataSource: AvatarsRemoteDataSource {
    public func fetch(ids: [Image.Identifier]) async -> [Image.Identifier: Image] {
        let cached: [Image.Identifier: Image] = cache.flatMap { cache in
            ids.reduce(into: [:]) { dict, id in
                if let status = elements[id] {
                    if case .fetched(let image) = status {
                        dict[id] = image
                    }
                } else if let cached = cache.get(imageId: id) {
                    elements[id] = .fetched(cached)
                    dict[id] = cached
                }
            }
        } ?? [:]
        let fetching: [Image.Identifier: Task<[Image.Identifier: Image], Never>] = ids
            .filter { cached[$0] == nil }
            .reduce(into: [:]) { dict, id in
                guard case .fetching(let task) = elements[id] else {
                    return
                }
                dict[id] = task
            }
        let toFetch = ids
            .filter { cached[$0] == nil }
            .filter { fetching[$0] == nil }
        let task = taskFactory.task {
            return await self.doFetch(
                ids: toFetch
            )
        }
        for id in toFetch {
            elements[id] = .fetching(query: task)
        }
        let fetchingWithJustRequestedValues = toFetch.reduce(into: fetching) { dict, id in
            guard case .fetching(let task) = elements[id] else {
                return
            }
            dict[id] = task
        }
        return await withTaskGroup(of: [Image.Identifier: Image].self) { group in
            for task in fetchingWithJustRequestedValues.values {
                group.addTask {
                    await task.value
                }
            }
            var result = cached
            for await dict in group {
                for (id, image) in dict {
                    result[id] = image
                }
            }
            return result
        }
    }
    
    private func doFetch(ids: [Image.Identifier]) async -> [Image.Identifier: Image] {
        guard !ids.isEmpty else {
            return [:]
        }
        let response: Operations.GetAvatars.Output
        do {
            response = try await api.getAvatars(
                .init(query: .init(ids: ids))
            )
        } catch {
            logE { "got network error getAvatars: \(error)" }
            return [:]
        }
        let images: [String: Components.Schemas.Image]
        do {
            images = try response.get()
        } catch {
            switch error {
            case .expected(let error):
                logW { "get avatars finished with error: \(error)" }
                return [:]
            case .undocumented(let statusCode, let payload):
                do {
                    let description = try await payload.logDescription
                    logE { "undocumented response on get avatars: code \(statusCode) body: \(description ?? "nil")" }
                } catch {
                    logE { "undocumented response on get avatars: code \(statusCode) body: \(payload) decodingFailure: \(error)" }
                }
                return [:]
            }
        }
        let result = images.mapValues { image in
            Image(id: image.id, base64: image.base64)
        }
        if let cache {
            for (_, image) in result {
                cache.store(image: image)
            }
        }
        for id in ids {
            if let image = result[id] {
                elements[id] = .fetched(image)
            } else {
                elements[id] = nil
            }
        }
        return result
    }
}

extension DefaultAvatarsRemoteDataSource: Loggable {}

extension DefaultAvatarsRemoteDataSource {
    final class Cache: Sendable, Loggable {
        let logger: Logger
        let fileManager: Filesystem.FileManager
        let directory: URL
        
        init(
            fileManager: Filesystem.FileManager,
            logger: Logger
        ) throws {
            guard
                let directory = FileManager.default
                    .urls(for: .cachesDirectory, in: .userDomainMask)
                    .first?
                    .appending(component: "verni.images")
            else {
                throw InternalError.error("system cache directory not found")
            }
            self.logger = logger
            self.fileManager = fileManager
            self.directory = directory
            do {
                try fileManager.createDirectory(at: directory)
            } catch {
                logE { "failed to create images cache directory" }
                throw error
            }
        }
        
        func store(image: Image) {
            guard let data = Data(base64Encoded: image.base64) else {
                return logE { "failed to get image data \(image.id)" }
            }
            do {
                try fileManager.createFile(
                    at: url(for: image.id),
                    content: data
                )
            } catch {
                return logE { "failed to store image data error: \(error)" }
            }
        }
        
        func get(imageId: Image.Identifier) -> Image? {
            do {
                return Image(
                    id: imageId,
                    base64: try fileManager.readFile(at: url(for: imageId))
                        .base64EncodedString()
                )
            } catch {
                return nil
            }
        }
        
        private nonisolated func url(for imageId: Image.Identifier) -> URL {
            directory.appending(component: "\(imageId).base64")
        }
    }
}
