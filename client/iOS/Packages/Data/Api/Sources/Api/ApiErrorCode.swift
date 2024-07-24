public enum ApiErrorCode: Int, Decodable {
    case incorrectCredentials = 1
    case wrongCredentialsFormat = 2
    case loginAlreadyTaken = 3
    case tokenExpired = 4
    case wrongAccessToken = 5
    case `internal` = 6
    case noSuchUser = 7
    case noSuchRequest = 8
    case alreadySend = 9
    case haveIncomingRequest = 10
    case alreadyFriends = 11
    case notAFriend = 12
    case badRequest = 13
    case dealNotFound = 14
    case isNotYourDeal = 15
}
