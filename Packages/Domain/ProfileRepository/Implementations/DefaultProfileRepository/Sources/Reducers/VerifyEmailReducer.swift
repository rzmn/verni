import Api
import Entities
import SyncEngine
internal import Convenience

func VerifyEmailReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.VerifyEmailOperation,
    state: State
) -> State {
    modify(state) { state in
        state.profile = state.profile.byInserting(
            operation: .init(
                kind: .mutate({ profile in
                    modify(profile) { profile in
                        if case .email(let email, _) = profile.email {
                            profile.email = .email(
                                email,
                                verified: payload.verifyEmail.verified
                            )
                        }
                    }
                }),
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
    }
}
