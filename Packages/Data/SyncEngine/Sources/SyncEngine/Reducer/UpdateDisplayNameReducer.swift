import Api
import Domain
import Base

func UpdateDisplayNameReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.UpdateDisplayNameOperation,
    state: State
) -> State {
    modify(state) {
        let userId = payload.updateDisplayName.userId
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
                                $0.payload.displayName = payload.updateDisplayName.displayName
                            }
                        }),
                        id: base.operationId,
                        timestamp: base.createdAt
                    )
                )
            )
        case .regular(let user):
            $0.users[userId] = .regular(
                user.byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .mutate({ user in
                            modify(user) {
                                $0.payload.displayName = payload.updateDisplayName.displayName
                            }
                        }),
                        id: base.operationId,
                        timestamp: base.createdAt
                    )
                )
            )
        }
    }
}
