import SwiftUI
import UIKit

public struct AvatarView: View {
    public typealias AvatarId = String

    @Observable @MainActor public class Repository: Sendable {
        private let get: (AvatarId) async -> Data?
        private var ramCache = [AvatarId: Data]()

        public init(getBlock: @escaping (AvatarId) async -> Data?) {
            get = getBlock
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
            return nil
        }

        public static var preview: Repository {
            Repository(getBlock: { _ in nil })
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
        if let avatar {
            if let imageData = imageData ?? repository.getIfCached(id: avatar) {
                if let image = UIImage(data: imageData) {
                    GeometryReader { geometry in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                } else {
                    failed
                }
            } else {
                loading
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
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
        } else {
            empty
        }
    }
    
    private var failed: some View {
        placeholder("❌")
    }
    
    private var empty: some View {
        placeholder("🌞")
    }
    
    private var loading: some View {
        ProgressView()
    }

    private func placeholder(_ emoji: String) -> some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text(emoji)
                        .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.6))
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

#if DEBUG

class ClassToIdentifyBundle {}

#Preview {
    VStack {
        AvatarView(
            avatar: nil
        )
        .frame(width: 250, height: 150)
        .clipShape(.rect(cornerRadius: 75))
        AvatarView(
            avatar: "123"
        )
        .frame(width: 150, height: 150)
        .clipShape(.rect(cornerRadius: 75))
    }
    .environment(AvatarView.Repository { _ in .stubAvatar })
    .environment(ColorPalette.light)
}

#endif
