import UIKit
import Domain
import Logging
internal import QRCode

private extension QRCode.Builder {
    func ifNotNil<T>(value: T?, block: (QRCode.Builder, T) -> QRCode.Builder) -> QRCode.Builder {
        guard let value else {
            return self
        }
        return block(self, value)
    }
}

public actor DefaultQRInviteUseCase: QRInviteUseCase, Loggable {
    private var cachedData = [String: Data]()
    private lazy var logoImage: CGImage? = {
        UIImage(named: "logo-mini", in: .module, with: nil)
            .flatMap { image in
                let size = CGSize(width: 128, height: 128)
                let renderer = UIGraphicsImageRenderer(size: size)
                return CIImage(
                    image: renderer.image { _ in
                        image.draw(in: CGRect(origin: .zero, size: size))
                    }
                )
            }
            .flatMap { image in
                CIContext(options: nil)
                    .createCGImage(image, from: image.extent)
            }
    }()
    private var cacheDirectory: URL? {
        FileManager.default.urls(
            for: .cachesDirectory,
            in: .allDomainsMask
        ).first?.appending(component: "verni.qr.cache")
    }
    public let logger: Logger
    private let urlById: (String) -> String

    public init(logger: Logger, urlById: @escaping (String) -> String) {
        self.logger = logger
        self.urlById = urlById
    }

    @MainActor public func generate(background: UIColor, tint: UIColor, size: Int, userId: String) async throws -> Data {
        try await doGenerate(background: background, tint: tint, size: size, userId: userId)
    }

    private func doGenerate(background: UIColor, tint: UIColor, size: Int, userId: String) throws -> Data {
        if let cached = getCached(for: userId) {
            return cached
        }
        let pngData = try QRCode.build
            .text(urlById(userId))
            .ifNotNil(value: logoImage, block: { builder, logoImage in
                builder.logo(logoImage, position: .squareCenter(inset: 12))
            })
            .foregroundColor(tint.cgColor)
            .backgroundColor(background.cgColor)
            .background.cornerRadius(4)
            .onPixels.shape(QRCode.PixelShape.RoundedPath())
            .eye.shape(QRCode.EyeShape.Squircle())
            .generate.image(dimension: size, representation: .png())
        cache(data: pngData, for: userId)
        return pngData
    }

    private func cachePath(for userId: String) -> URL? {
        cacheDirectory?.appending(
            component: "\(userId)_v2.svg"
        )
    }

    private func getCached(for userId: String) -> Data? {
        if let cached = cachedData[userId] {
            return cached
        }
        guard let filepath = cachePath(for: userId) else {
            return nil
        }
        let data: Data
        do {
            data = try Data(contentsOf: filepath)
        } catch {
            logE { "cannot read cached data from \(filepath) due error: \(error)" }
            return nil
        }
        cache(data: data, for: userId)
        return data
    }

    private func cache(data: Data, for userId: String) {
        cachedData[userId] = data
        guard let filepath = cachePath(for: userId) else {
            return
        }
        let folder = filepath.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            logE { "cannot create cache directory at \(folder) due error: \(error)" }
            return
        }
        do {
            try data.write(to: filepath)
        } catch {
            logE { "cannot cache url \(userId) at \(filepath) due error: \(error)" }
            return
        }
    }
}
