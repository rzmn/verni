import Api
import Domain
import Base

func BindUserReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.BindUserOperation,
    state: State
) -> State {
    modify(state) {
        let userId = payload.bindUser.oldId
        let user = state.users[userId, default: .user(
            id: userId,
            ownerId: base.authorId
        )]
        switch user {
        case .sandbox(let user):
            $0.users[userId] = .sandbox(
                user.byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .mutate({ user in
                            modify(user) {
                                $0.bindedTo = payload.bindUser.newId
                            }
                        }),
                        id: base.operationId,
                        timestamp: base.createdAt
                    )
                )
            )
        case .regular:
            assertionFailure()
        }
    }
}
