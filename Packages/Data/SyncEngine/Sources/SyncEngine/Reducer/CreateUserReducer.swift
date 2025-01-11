import Api
import Domain
import Base

func CreateUserReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.CreateUserOperation,
    state: State
) -> State {
    modify(state) {
        let userId = payload.createUser.userId
        let user = state.users[userId, default: .user(
            id: userId,
            ownerId: base.authorId
        )]
        switch user {
        case .sandbox(let user):
            $0.users[userId] = .sandbox(
                user.byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .create(
                            SandboxUser(
                                id: userId,
                                ownerId: base.authorId,
                                payload: UserPayload(
                                    displayName: payload.createUser.displayName,
                                    avatar: nil
                                ),
                                bindedTo: nil
                            )
                        ),
                        id: base.operationId,
                        timestamp: base.createdAt
                    )
                )
            )
        case .regular(let user):
            $0.users[payload.createUser.userId] = .regular(
                user.byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .create(
                            User(
                                id: userId,
                                payload: UserPayload(
                                    displayName: payload.createUser.displayName,
                                    avatar: nil
                                )
                            )
                        ),
                        id: base.operationId,
                        timestamp: base.createdAt
                    )
                )
            )
        }
    }
}
