import SwiftUI
import UIKit

private extension String {
    func image(fitSize: CGSize?) -> UIImage? {
        let size = fitSize ?? CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: size.width)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public struct AvatarView: View {
    public typealias AvatarId = String
    
    @Observable @MainActor public class Repository: Sendable {
        let get: (AvatarId) async -> Data?
        
        public init(getBlock: @escaping (AvatarId) async -> Data?) {
            get = getBlock
        }
        
        public static var preview: Repository {
            Repository { _ in nil }
        }
    }
    
    @Environment(Repository.self) var repository
    @State private var imageData: Data?
    @State private var task: Task<Void, Never>?
    private let avatar: AvatarId?
    private let fitSize: CGSize
    
    public init(fitSize: CGSize, avatar: AvatarId?) {
        self.fitSize = fitSize
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
        if let imageData {
            if let image = UIImage(data: imageData) {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width)
                        .clipped()
                }
            } else {
                failedToLoadStub
            }
        } else {
            loadingStub
                .onAppear {
                    guard let avatar else {
                        return
                    }
                    task = Task {
                        guard let data = await repository.get(avatar) else {
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
                      
    @ViewBuilder var noAvatarStub: some View {
        Image(uiImage: "🥷".image(fitSize: self.fitSize) ?? UIImage())
            .frame(width: fitSize.width, height: fitSize.height)
    }
    
    @ViewBuilder var failedToLoadStub: some View {
        Image(uiImage: "❌".image(fitSize: self.fitSize) ?? UIImage())
            .frame(width: fitSize.width, height: fitSize.height)
    }
    
    @ViewBuilder var loadingStub: some View {
        Image(uiImage: "⌛".image(fitSize: self.fitSize) ?? UIImage())
            .frame(width: fitSize.width, height: fitSize.height)
    }
}
