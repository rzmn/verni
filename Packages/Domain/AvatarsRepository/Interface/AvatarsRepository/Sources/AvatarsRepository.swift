import Foundation
import Entities
import AsyncExtensions

public enum UploadImageError: Error {
    case invalidImageData
    case `internal`(Error)
}

public protocol AvatarsRepository {
    var updates: any AsyncBroadcast<[Image.Identifier: Image]> { get }

    subscript(
        id: Image.Identifier
    ) -> Image? { get async }
    
    func upload(
        image data: Image.Base64Data
    ) async throws(UploadImageError) -> Image.Identifier
}
