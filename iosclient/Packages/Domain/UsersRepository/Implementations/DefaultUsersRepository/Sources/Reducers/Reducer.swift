import Api

typealias Reducer = (Components.Schemas.SomeOperation, State) -> State

func DefaultReducer(
    createUserReducer: @escaping (
        Components.Schemas.BaseOperation, Components.Schemas.CreateUserOperation, State
    ) -> State,
    updateDisplayNameReducer: @escaping (
        Components.Schemas.BaseOperation, Components.Schemas.UpdateDisplayNameOperation, State
    ) -> State,
    updateAvatarReducer: @escaping (
        Components.Schemas.BaseOperation, Components.Schemas.UpdateAvatarOperation, State
    ) -> State,
    bindUserReducer: @escaping (
        Components.Schemas.BaseOperation, Components.Schemas.BindUserOperation, State
    ) -> State
) -> Reducer {
    return { operation, state in
        switch operation.value2 {
        case .CreateUserOperation(let payload):
            createUserReducer(operation.value1, payload, state)
        case .UpdateDisplayNameOperation(let payload):
            updateDisplayNameReducer(operation.value1, payload, state)
        case .UpdateAvatarOperation(let payload):
            updateAvatarReducer(operation.value1, payload, state)
        case .BindUserOperation(let payload):
            bindUserReducer(operation.value1, payload, state)
        default:
            state
        }
    }
}
