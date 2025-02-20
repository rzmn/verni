import Api
import Entities
internal import Convenience

func UploadImageReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.UploadImageOperation,
    state: State
) -> State {
    modify(state) {
        let image = Image(
            id: payload.uploadImage.imageId,
            base64: payload.uploadImage.base64
        )
        $0.images[image.id] = image
    }
}
