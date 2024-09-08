import Domain
import Foundation

actor AvatarsOfflineRepository {
    private let defaultDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first

    init() {
        guard let defaultDirectory else {
            return
        }
        if !FileManager.default.fileExists(atPath: defaultDirectory.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: defaultDirectory, withIntermediateDirectories: true)
        }
    }

    func store(data: Data, for id: Avatar.ID) async {
        defaultDirectory.flatMap {
            try? data.write(to: $0.appending(component: name(for: id)))
        }
    }

    func getData(for id: Avatar.ID) async -> Data? {
        defaultDirectory.flatMap {
            try? Data(contentsOf: $0.appending(component: name(for: id)))
        }
    }

    private func name(for id: Avatar.ID) -> String {
        "acnty_avatar_\(id)"
    }
}
