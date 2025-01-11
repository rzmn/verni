import Api
import Domain
import Base

func UpdateAvatarReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.UpdateAvatarOperation,
    state: State
) -> State {
    modify(state) {
        let userId = payload.updateAvatar.userId
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
                                $0.payload.avatar = payload.updateAvatar.imageId
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
                                $0.payload.avatar = payload.updateAvatar.imageId
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
