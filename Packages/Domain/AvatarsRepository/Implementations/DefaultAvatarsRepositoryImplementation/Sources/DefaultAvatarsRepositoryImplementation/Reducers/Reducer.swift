import Api

typealias Reducer = (Components.Schemas.Operation, State) -> State

func DefaultReducer(
    uploadImageReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.UploadImageOperation, State) -> State
) -> Reducer {
    return { operation, state in
        switch operation.value2 {
        case .UploadImageOperation(let payload):
            uploadImageReducer(operation.value1, payload, state)
        default:
            state
        }
    }
}
