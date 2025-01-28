import Api

typealias Reducer = (Components.Schemas.Operation, State) -> State

func DefaultReducer(
    createSpendingGroupReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.CreateSpendingGroupOperation, State) -> State,
    deleteSpendingGroupReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.DeleteSpendingGroupOperation, State) -> State,
    createSpendingReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.CreateSpendingOperation, State) -> State,
    deleteSpendingReducer: @escaping (Components.Schemas.BaseOperation, Components.Schemas.DeleteSpendingOperation, State) -> State
) -> Reducer {
    return { operation, state in
        switch operation.value2 {
        case .CreateSpendingOperation(let payload):
            createSpendingReducer(operation.value1, payload, state)
        case .CreateSpendingGroupOperation(let payload):
            createSpendingGroupReducer(operation.value1, payload, state)
        case .DeleteSpendingOperation(let payload):
            deleteSpendingReducer(operation.value1, payload, state)
        case .DeleteSpendingGroupOperation(let payload):
            deleteSpendingGroupReducer(operation.value1, payload, state)
        default:
            state
        }
    }
}

