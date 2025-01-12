import Api
import Domain
import Base

typealias Reducer = (Components.Schemas.Operation, State) -> State

func DefaultReducer(
    createUserReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.CreateUserOperation, State) -> State,
    updateDisplayNameReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.UpdateDisplayNameOperation, State) -> State,
    updateAvatarReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.UpdateAvatarOperation, State) -> State,
    bindUserReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.BindUserOperation, State) -> State,
    createSpendingGroupReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.CreateSpendingGroupOperation, State) -> State,
    deleteSpendingGroupReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.DeleteSpendingGroupOperation, State) -> State,
    createSpendingReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.CreateSpendingOperation, State) -> State,
    deleteSpendingReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.DeleteSpendingOperation, State) -> State
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
        case .CreateSpendingGroupOperation(let payload):
            createSpendingGroupReducer(operation.value1, payload, state)
        case .DeleteSpendingGroupOperation(let payload):
            deleteSpendingGroupReducer(operation.value1, payload, state)
        case .CreateSpendingOperation(let payload):
            createSpendingReducer(operation.value1, payload, state)
        case .DeleteSpendingOperation(let payload):
            deleteSpendingReducer(operation.value1, payload, state)
        }
    }
}
