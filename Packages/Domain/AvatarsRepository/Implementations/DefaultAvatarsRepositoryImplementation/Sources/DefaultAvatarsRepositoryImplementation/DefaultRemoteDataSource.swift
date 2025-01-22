import Entities
import AvatarsRepository
import Api
import Filesystem
import Foundation
import Logging
internal import Convenience

public final class DefaultRemoteDataSource: Sendable {
    public let logger: Logger
    private let cache: Cache
    private let api: APIProtocol
    
    init(logger: Logger, cache: Cache, api: APIProtocol) {
        self.logger = logger
        self.cache = cache
        self.api = api
    }
}

extension DefaultRemoteDataSource: AvatarsRemoteDataSource {
    public func fetch(ids: [Image.Identifier]) async -> [Image.Identifier: Image] {
        var cached = [Image.Identifier: Image]()
        for id in ids {
            cached[id] = await cache.get(imageId: id)
        }
        let fetched = await doFetch(
            ids: ids.filter { cached[$0] == nil }
        )
        return cached.reduce(into: fetched) { dict, item in
            dict[item.key] = item.value
        }
    }
    
    private func doFetch(ids: [Image.Identifier]) async -> [Image.Identifier: Image] {
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
                logE { "get avatars undocumented response code: \(statusCode), payload: \(payload)" }
                return [:]
            }
        }
        let result = images.mapValues { image in
            Image(id: image.id, base64: image.base64)
        }
        for (_, image) in result {
            await cache.store(image: image)
        }
        return result
    }
}

extension DefaultRemoteDataSource: Loggable {}

extension DefaultRemoteDataSource {
    actor Cache: Loggable {
        let logger: Logger
        let fileManager: Filesystem.FileManager
        let directory: URL
        
        init?(
            fileManager: Filesystem.FileManager,
            logger: Logger
        ) {
            guard
                let directory = FileManager.default
                    .urls(for: .cachesDirectory, in: .userDomainMask)
                    .first?
                    .appending(component: "verni.images")
            else {
                return nil
            }
            self.logger = logger
            self.fileManager = fileManager
            self.directory = directory
            do {
                try fileManager.createDirectory(at: directory)
            } catch {
                logE { "failed to create images cache directory" }
                return nil
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
                    base64: try Data(
                        contentsOf: url(for: imageId)
                    ).base64EncodedString()
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
