import Api

typealias Reducer = (Components.Schemas.Operation, State) -> State

func DefaultReducer(
    verifyEmailReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.VerifyEmailOperation, State) -> State,
    updateEmailReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.UpdateEmailOperation, State) -> State
) -> Reducer {
    return { operation, state in
        switch operation.value2 {
        case .VerifyEmailOperation(let payload):
            verifyEmailReducer(operation.value1, payload, state)
        case .UpdateEmailOperation(let payload):
            updateEmailReducer(operation.value1, payload, state)
        default:
            state
        }
    }
}
