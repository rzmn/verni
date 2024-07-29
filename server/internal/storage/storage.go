package storage

type FriendStatus int

const (
	FriendStatusNo = iota
	FriendStatusIncomingRequest
	FriendStatusOutgoingRequest
	FriendStatusFriends
	FriendStatusMe
)

type UserId string

type Avatar struct {
	Url *string `json:"url"`
}

type ProfileInfo struct {
	User          User   `json:"user"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"emailVerified"`
}

type User struct {
	Id           UserId       `json:"id"`
	DisplayName  string       `json:"displayName"`
	Avatar       Avatar       `json:"avatar"`
	FriendStatus FriendStatus `json:"friendStatus"`
}

type UserCredentials struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type AuthToken struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
}

type Deal struct {
	Timestamp int64      `json:"timestamp"`
	Details   string     `json:"details"`
	Cost      int64      `json:"cost"`
	Currency  string     `json:"currency"`
	Spendings []Spending `json:"spendings"`
}

type IdentifiableDeal struct {
	Deal
	Id string `json:"id"`
}

type Spending struct {
	UserId UserId `json:"userId"`
	Cost   int64  `json:"cost"`
}

type SpendingsPreview struct {
	Counterparty string           `json:"counterparty"`
	Balance      map[string]int64 `json:"balance"`
}

type Storage interface {
	GetAccountInfo(uid UserId) (*ProfileInfo, error)

	GetUserId(email string) (*UserId, error)
	StoreEmailValidationToken(email string, token string) error
	ExtractEmailValidationToken(email string) (*string, error)
	ValidateEmail(email string) error

	IsUserExists(uid UserId) (bool, error)
	CheckCredentials(credentials UserCredentials) (bool, error)
	StoreCredentials(uid UserId, credentials UserCredentials) error

	StoreDisplayName(uid UserId, displayName string) error
	StoreAvatarBase64(uid UserId, avatarBase64 string) error

	StoreRefreshToken(token string, uid UserId) error
	GetRefreshToken(uid UserId) (*string, error)
	RemoveRefreshToken(uid UserId) error

	StoreFriendRequest(sender UserId, target UserId) error
	HasFriendRequest(sender UserId, target UserId) (bool, error)
	RemoveFriendRequest(sender UserId, target UserId) error

	GetIncomingRequests(uid UserId) ([]UserId, error)
	GetPendingRequests(uid UserId) ([]UserId, error)

	StoreFriendship(friendA UserId, friendB UserId) error
	HasFriendship(friendA UserId, friendB UserId) (bool, error)
	RemoveFriendship(friendA UserId, friendB UserId) error

	GetFriends(uid UserId) ([]UserId, error)

	GetUsers(sender UserId, ids []UserId) ([]User, error)
	SearchUsers(sender UserId, query string) ([]User, error)

	InsertDeal(deal Deal) error
	HasDeal(did string) (bool, error)
	RemoveDeal(did string) error

	GetDeals(counterparty1 UserId, counterparty2 UserId) ([]IdentifiableDeal, error)
	GetCounterparties(uid UserId) ([]SpendingsPreview, error)
	GetCounterpartiesForDeal(did string) ([]UserId, error)

	Close()
}
