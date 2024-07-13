import Foundation
import Combine
import Domain
import DI

actor FriendsSearchModel {
    let subject = CurrentValueSubject<FriendsSearchState, Never>(FriendsSearchState(content: .initial))
    
    private let appRouter: AppRouter
    private let usersRepository: UsersRepository
    private let di: ActiveSessionDIContainer
    private lazy var presenter = FriendsSearchPresenter(model: self, appRouter: appRouter)
    private weak var friendsModel: FriendsModel?

    init(di: ActiveSessionDIContainer, appRouter: AppRouter) async {
        self.di = di
        usersRepository = di.usersRepository()
        self.appRouter = appRouter
    }

    func setFriendsModel(_ model: FriendsModel) async {
        friendsModel = model
    }

    func start() async {
        await presenter.start()
    }

    func open(user: User) async {
        guard let friendsModel else {
            return
        }
        await friendsModel.showUser(user: user)
    }

    func search(query: String) async {
        subject.send(FriendsSearchState(subject.value, content: .loading(previous: subject.value.content)))
        switch await usersRepository.searchUsers(query: query) {
        case .success(let users):
            subject.send(FriendsSearchState(subject.value, content: .loaded(users)))
        case .failure(let error):
            subject.send(FriendsSearchState(subject.value, content: .failed(previous: subject.value.content, "error \(error)")))
        }
    }
}
