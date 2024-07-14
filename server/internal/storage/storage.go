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

type User struct {
	Login        UserId       `json:"login"`
	FriendStatus FriendStatus `json:"friendStatus"`
}

type UserCredentials struct {
	Login    string `json:"login" validate:"required"`
	Password string `json:"password" validate:"required"`
}

type AuthToken struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
}

type Deal struct {
	Timestamp int64      `json:"timestamp"`
	Details   string     `json:"details"`
	Cost      int        `json:"cost"`
	Currency  string     `json:"currency"`
	Spendings []Spending `json:"spendings"`
}

type IdentifiableDeal struct {
	Deal
	Id int64 `json:"id"`
}

type Spending struct {
	UserId string `json:"userId"`
	Cost   int    `json:"cost"`
}

type SpendingsPreview struct {
	Counterparty string         `json:"counterparty"`
	Balance      map[string]int `json:"balance"`
}
