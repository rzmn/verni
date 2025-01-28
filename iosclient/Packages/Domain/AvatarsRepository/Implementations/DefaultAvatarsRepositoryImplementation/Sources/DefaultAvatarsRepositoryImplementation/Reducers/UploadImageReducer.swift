import Api
import Entities
internal import Convenience

func UploadImageReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.UploadImageOperation,
    state: State
) -> State {
    modify(state) {
        let imageId = payload.uploadImage.imageId
        $0.images[imageId] = state.images[imageId, default: .init(initial: nil)]
            .byInserting(
                operation: .init(
                    kind: .create(
                        Image(
                            id: payload.uploadImage.imageId,
                            base64: payload.uploadImage.base64
                        )
                    ),
                    id: base.operationId,
                    timestamp: base.createdAt
                )
            )
    }
}
