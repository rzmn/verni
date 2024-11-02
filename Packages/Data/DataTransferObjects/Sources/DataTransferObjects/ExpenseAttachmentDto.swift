import Base

public struct ExpenseAttachmentDto: Codable, Sendable, Equatable {
    let imageId: ImageDto.Identifier?
}
