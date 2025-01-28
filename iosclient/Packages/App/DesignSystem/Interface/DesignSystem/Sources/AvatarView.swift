import SwiftUI
import UIKit

public struct AvatarView: View {
    public typealias AvatarId = String

    @Observable @MainActor public class Repository: Sendable {
        private let get: (AvatarId) async -> Data?
        private let getIfCached: (AvatarId) -> Data?
        private var ramCache = [AvatarId: Data]()

        public init(getBlock: @escaping (AvatarId) async -> Data?, getIfCachedBlock: @escaping (AvatarId) -> Data?) {
            get = getBlock
            getIfCached = getIfCachedBlock
        }

        func get(id: AvatarId) async -> Data? {
            let data = await get(id)
            if let data {
                Task { @MainActor in
                    self.ramCache[id] = data
                }
            }
            return data
        }

        func getIfCached(id: AvatarId) -> Data? {
            if let data = ramCache[id] {
                return data
            }
            if let data = getIfCached(id) {
                ramCache[id] = data
                return data
            }
            return nil
        }

        public static var preview: Repository {
            Repository(getBlock: {_ in nil}, getIfCachedBlock: { _ in nil })
        }
    }

    @Environment(ColorPalette.self) var colors
    @Environment(Repository.self) var repository
    @State private var imageData: Data?
    @State private var task: Task<Void, Never>?
    private let avatar: AvatarId?

    public init(avatar: AvatarId?) {
        self.avatar = avatar
    }

    public var body: some View {
        content
            .onDisappear {
                task?.cancel()
                task = nil
            }
    }

    @ViewBuilder private var content: some View {
        if let imageData = imageData ?? avatar.flatMap(repository.getIfCached(id:)) {
            if let image = UIImage(data: imageData) {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            } else {
                placeholder("[debug] placeholder for `failed to load`")
            }
        } else {
            placeholder("[debug] placeholder for `loading`")
                .onAppear {
                    guard let avatar else {
                        return
                    }
                    task = Task {
                        guard let data = await repository.get(id: avatar) else {
                            return
                        }
                        if Task.isCancelled {
                            return
                        }
                        Task { @MainActor in
                            imageData = data
                            self.task = nil
                        }
                    }
                }
        }
    }

    private func placeholder(_ text: String) -> some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                Spacer()
                Text(text)
                    .font(.medium(size: 15))
                    .foregroundStyle(colors.text.primary.default)
                Spacer()
            }
            Spacer()
        }
    }

}
