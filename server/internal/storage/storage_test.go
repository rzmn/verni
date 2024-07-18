package storage_test

import (
	"accounty/internal/storage"
	"accounty/internal/storage/ydbStorage"
	"log"
	"testing"

	"github.com/google/uuid"
)

func getStorage(t *testing.T) storage.Storage {
	storage, err := ydbStorage.NewUnauthorized("grpc://localhost:2136?database=/local")
	if err != nil {
		t.Fatalf("%v", err)
	}
	return storage
}

func TestIsUserExistsFalse(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	exists, err := s.IsUserExists(uid)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if exists {
		t.Fatalf("unexpected exists=true")
	}
}

func TestIsUserExistsTrue(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	pwd := uuid.New().String()
	if err := s.StoreCredentials(storage.UserCredentials{Login: uid, Password: pwd}); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	exists, err := s.IsUserExists(uid)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if !exists {
		t.Fatalf("unexpected exists=false")
	}
}

func TestCheckCredentialsTrue(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	pwd := uuid.New().String()
	credentials := storage.UserCredentials{Login: uid, Password: pwd}
	if err := s.StoreCredentials(credentials); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	passed, err := s.CheckCredentials(credentials)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if !passed {
		t.Fatalf("unexpected passed=false")
	}
}

func TestCheckCredentialsFalse(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	pwd := uuid.New().String()
	credentials := storage.UserCredentials{Login: uid, Password: pwd}
	if err := s.StoreCredentials(credentials); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	credentials.Password = uuid.New().String()
	passed, err := s.CheckCredentials(credentials)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if passed {
		t.Fatalf("unexpected passed=true")
	}
}

func TestCheckCredentialsEmpty(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	pwd := uuid.New().String()
	credentials := storage.UserCredentials{Login: uid, Password: pwd}
	passed, err := s.CheckCredentials(credentials)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if passed {
		t.Fatalf("unexpected passed=true")
	}
}

func TestStoreAndRemoveRefreshToken(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	token := uuid.New().String()
	if err := s.StoreRefreshToken(token, uid); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	tokenFromStorage, err := s.GetRefreshToken(uid)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if token != *tokenFromStorage {
		t.Fatalf("tokens are not equal")
	}
	if err := s.RemoveRefreshToken(uid); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	nilTokenFromStorage, err := s.GetRefreshToken(uid)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if nilTokenFromStorage != nil {
		t.Fatalf("token should be nil")
	}
}

func TestGetRefreshTokenEmpty(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	token, err := s.GetRefreshToken(uid)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if token != nil {
		t.Fatalf("token should be nil")
	}
}

func TestStoreAndRemoveFriendRequest(t *testing.T) {
	s := getStorage(t)
	sender := storage.UserId(uuid.New().String())
	target := storage.UserId(uuid.New().String())

	if err := s.StoreFriendRequest(sender, target); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	exists, err := s.HasFriendRequest(sender, target)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if !exists {
		t.Fatalf("exists should be true")
	}
	exists, err = s.HasFriendRequest(target, sender)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if exists {
		t.Fatalf("exists should be false")
	}
	if err := s.RemoveFriendRequest(sender, target); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	exists, err = s.HasFriendRequest(sender, target)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if exists {
		t.Fatalf("exists should be false")
	}
}

func TestHasFriendRequestEmpty(t *testing.T) {
	s := getStorage(t)
	sender := storage.UserId(uuid.New().String())
	target := storage.UserId(uuid.New().String())
	exists, err := s.HasFriendRequest(sender, target)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if exists {
		t.Fatalf("exists should be false")
	}
}

func TestGetIncomingRequests(t *testing.T) {
	s := getStorage(t)
	sender := storage.UserId(uuid.New().String())
	target := storage.UserId(uuid.New().String())

	if err := s.StoreFriendRequest(sender, target); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	incoming, err := s.GetIncomingRequests(target)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(incoming) != 1 || incoming[0] != sender {
		t.Fatalf("incoming should have only sender")
	}
	incoming, err = s.GetIncomingRequests(sender)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(incoming) != 0 {
		t.Fatalf("incoming should be empty")
	}
}

func TestGetIncomingRequestsEmpty(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	incoming, err := s.GetIncomingRequests(uid)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(incoming) != 0 {
		t.Fatalf("incoming should be empty")
	}
}

func TestGetPendingRequests(t *testing.T) {
	s := getStorage(t)
	sender := storage.UserId(uuid.New().String())
	target := storage.UserId(uuid.New().String())

	if err := s.StoreFriendRequest(sender, target); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	pending, err := s.GetPendingRequests(sender)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(pending) != 1 || pending[0] != target {
		t.Fatalf("pending should have only target")
	}
	pending, err = s.GetPendingRequests(target)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(pending) != 0 {
		t.Fatalf("pending should be empty")
	}
}

func TestGetPendingRequestsEmpty(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	incoming, err := s.GetPendingRequests(uid)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(incoming) != 0 {
		t.Fatalf("incoming should be empty")
	}
}

func TestStoreAndRemoveFriendship(t *testing.T) {
	s := getStorage(t)
	friendA := storage.UserId(uuid.New().String())
	friendB := storage.UserId(uuid.New().String())

	if err := s.StoreFriendship(friendA, friendB); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	has, err := s.HasFriendship(friendA, friendB)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if !has {
		t.Fatalf("has should be true")
	}
	has, err = s.HasFriendship(friendB, friendA)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if !has {
		t.Fatalf("has should be true")
	}
	if err := s.RemoveFriendship(friendA, friendB); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	has, err = s.HasFriendship(friendA, friendB)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if has {
		t.Fatalf("has should be false")
	}
	has, err = s.HasFriendship(friendB, friendA)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if has {
		t.Fatalf("has should be false")
	}
}

func TestHasFriendshipEmpty(t *testing.T) {
	s := getStorage(t)
	friendA := storage.UserId(uuid.New().String())
	friendB := storage.UserId(uuid.New().String())
	has, err := s.HasFriendship(friendA, friendB)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if has {
		t.Fatalf("has should be false")
	}
	has, err = s.HasFriendship(friendB, friendA)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if has {
		t.Fatalf("has should be false")
	}
}

func TestGetFriends(t *testing.T) {
	s := getStorage(t)
	friendA := storage.UserId(uuid.New().String())
	friendB := storage.UserId(uuid.New().String())

	if err := s.StoreFriendship(friendA, friendB); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	friendsOfA, err := s.GetFriends(friendA)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(friendsOfA) != 1 || friendsOfA[0] != friendB {
		t.Fatalf("friendsOfA should contain only friendB")
	}
	friendsOfB, err := s.GetFriends(friendB)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(friendsOfB) != 1 || friendsOfB[0] != friendA {
		t.Fatalf("friendsOfB should contain only friendA")
	}
	if err := s.RemoveFriendship(friendB, friendA); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	friendsOfA, err = s.GetFriends(friendA)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(friendsOfA) != 0 {
		t.Fatalf("friendsOfA should be empty")
	}
	friendsOfB, err = s.GetFriends(friendB)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(friendsOfB) != 0 {
		t.Fatalf("friendsOfB should be empty")
	}
}

func TestGetFriendsEmpty(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	friends, err := s.GetFriends(uid)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(friends) != 0 {
		t.Fatalf("friends should be empty")
	}
}

func TestGetUsers(t *testing.T) {
	s := getStorage(t)
	me := storage.UserId(uuid.New().String())
	mySubscriber := storage.UserId(uuid.New().String())
	mySubscription := storage.UserId(uuid.New().String())
	myFriend := storage.UserId(uuid.New().String())
	randomUser := storage.UserId(uuid.New().String())
	userWhoDoesNotExist := storage.UserId(uuid.New().String())

	usersToCreate := []storage.UserId{me, mySubscriber, mySubscription, myFriend, randomUser}
	for i := 0; i < len(usersToCreate); i++ {
		pwd := uuid.New().String()
		if err := s.StoreCredentials(storage.UserCredentials{Login: usersToCreate[i], Password: pwd}); err != nil {
			t.Fatalf("unexpected err: %v", err)
		}
	}
	if err := s.StoreFriendRequest(me, mySubscription); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if err := s.StoreFriendRequest(mySubscriber, me); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if err := s.StoreFriendship(me, myFriend); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	users, err := s.GetUsers(me, []storage.UserId{me, mySubscriber, mySubscription, myFriend, randomUser, userWhoDoesNotExist})
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(usersToCreate) != len(users) {
		t.Fatalf("should get all created users, found %v", users)
	}
	passedUsers := map[storage.UserId]bool{}
	for i := 0; i < len(users); i++ {
		if users[i].Login == me && users[i].FriendStatus == storage.FriendStatusMe {
			passedUsers[me] = true
		}
		if users[i].Login == mySubscriber && users[i].FriendStatus == storage.FriendStatusIncomingRequest {
			passedUsers[mySubscriber] = true
		}
		if users[i].Login == mySubscription && users[i].FriendStatus == storage.FriendStatusOutgoingRequest {
			passedUsers[mySubscription] = true
		}
		if users[i].Login == myFriend && users[i].FriendStatus == storage.FriendStatusFriends {
			passedUsers[myFriend] = true
		}
		if users[i].Login == randomUser && users[i].FriendStatus == storage.FriendStatusNo {
			passedUsers[randomUser] = true
		}
	}
	if len(passedUsers) != len(users) {
		t.Fatalf("should pass all created users, found %v", passedUsers)
	}
}

func TestGetUsersEmpty(t *testing.T) {
	s := getStorage(t)
	uid := storage.UserId(uuid.New().String())
	users, err := s.GetUsers(uid, []storage.UserId{uid})
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(users) != 0 {
		t.Fatalf("users should be empty, found %v", users)
	}
}

func TestSearchUsers(t *testing.T) {
	s := getStorage(t)
	me := storage.UserId(uuid.New().String())
	otherUser := storage.UserId(uuid.New().String())

	usersToCreate := []storage.UserId{me, otherUser}
	for i := 0; i < len(usersToCreate); i++ {
		pwd := uuid.New().String()
		if err := s.StoreCredentials(storage.UserCredentials{Login: usersToCreate[i], Password: pwd}); err != nil {
			t.Fatalf("unexpected err: %v", err)
		}
	}
	result1, err := s.SearchUsers(me, string(otherUser))
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(result1) != 1 || result1[0].Login != otherUser {
		t.Fatalf("result1 should contain only otherUser, found: %v", result1)
	}
	result2, err := s.SearchUsers(me, string(otherUser)[0:len(otherUser)-3])
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(result2) != 1 || result2[0].Login != otherUser {
		t.Fatalf("result2 should contain only otherUser for req %s, found: %v", string(otherUser)[0:len(otherUser)-3], result2)
	}
}

func TestSearchUsersEmpty(t *testing.T) {
	s := getStorage(t)
	me := storage.UserId(uuid.New().String())
	result, err := s.SearchUsers(me, "")
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(result) != 0 {
		t.Fatalf("result should be empty, found: %v", result)
	}
	result, err = s.SearchUsers(me, "x")
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(result) != 0 {
		t.Fatalf("result should be empty, found: %v", result)
	}
}

func TestDealsAndCounterparties(t *testing.T) {
	s := getStorage(t)
	counterparty1 := storage.UserId(uuid.New().String())
	counterparty2 := storage.UserId(uuid.New().String())
	cost1 := int64(456)
	cost2 := int64(888)
	currency := uuid.New().String()

	deal1 := storage.Deal{
		Timestamp: 123,
		Details:   uuid.New().String(),
		Cost:      cost1,
		Currency:  currency,
		Spendings: []storage.Spending{
			{
				UserId: counterparty1,
				Cost:   cost1,
			},
			{
				UserId: counterparty2,
				Cost:   -cost1,
			},
		},
	}
	if err := s.InsertDeal(deal1); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	deal2 := storage.Deal{
		Timestamp: 123,
		Details:   uuid.New().String(),
		Cost:      cost2,
		Currency:  currency,
		Spendings: []storage.Spending{
			{
				UserId: counterparty2,
				Cost:   -cost2 / 2,
			},
			{
				UserId: counterparty1,
				Cost:   cost2 / 2,
			},
		},
	}
	if err := s.InsertDeal(deal2); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	deals, err := s.GetDeals(counterparty1, counterparty2)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(deals) != 2 {
		t.Fatalf("should be 2 deals, found: %v", deals)
	} else {
		log.Printf("deals ok: %v\n", deals)
	}
	counterparties, err := s.GetCounterparties(counterparty1)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(counterparties) != 1 || counterparties[0].Counterparty != string(counterparty2) || counterparties[0].Balance[currency] != (cost1+cost2/2) {
		t.Fatalf("unexpected counterparty, found: %v", counterparties)
	}
	counterparties, err = s.GetCounterparties(counterparty2)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(counterparties) != 1 || counterparties[0].Counterparty != string(counterparty1) || counterparties[0].Balance[currency] != -(cost1+cost2/2) {
		t.Fatalf("unexpected counterparty, found: %v", counterparties)
	}
}

func TestInsertAndRemoveDeal(t *testing.T) {
	s := getStorage(t)
	counterparty1 := storage.UserId(uuid.New().String())
	counterparty2 := storage.UserId(uuid.New().String())
	cost := int64(456)
	currency := uuid.New().String()

	deal := storage.Deal{
		Timestamp: 123,
		Details:   uuid.New().String(),
		Cost:      cost,
		Currency:  currency,
		Spendings: []storage.Spending{
			{
				UserId: counterparty1,
				Cost:   cost,
			},
			{
				UserId: counterparty2,
				Cost:   -cost,
			},
		},
	}

	if err := s.InsertDeal(deal); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	deals, err := s.GetDeals(counterparty1, counterparty2)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if len(deals) != 1 {
		t.Fatalf("deals len should be 1, found: %v", deals)
	}
	exists, err := s.HasDeal(deals[0].Id)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if !exists {
		t.Fatalf("deal should exists: %v", err)
	}
	if err := s.RemoveDeal(deals[0].Id); err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	exists, err = s.HasDeal(deals[0].Id)
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if exists {
		t.Fatalf("deal should not exists: %v", err)
	}
}
