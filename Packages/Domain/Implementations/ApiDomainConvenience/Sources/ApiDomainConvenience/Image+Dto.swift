import Domain
import Api

extension Avatar {
    public init(dto: Components.Schemas.Image) {
        self = Avatar(
            id: dto.id,
            base64: dto.base64
        )
    }
}

extension Components.Schemas.Image {
    public init(domain image: Avatar) {
        self = Components.Schemas.Image(
            id: image.id,
            base64: image.base64
        )
    }
}
