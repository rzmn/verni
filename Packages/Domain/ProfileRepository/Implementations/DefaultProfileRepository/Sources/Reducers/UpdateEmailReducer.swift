import Api
import Entities
import SyncEngine
internal import Convenience

func UpdateEmailReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.UpdateEmailOperation,
    state: State
) -> State {
    modify(state) { state in
        state.profile = state.profile.byInserting(
            operation: .init(
                kind: .mutate({ profile in
                    modify(profile) { profile in
                        profile.email = .email(
                            payload.updateEmail.email,
                            verified: false
                        )
                    }
                }),
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
    }
}
